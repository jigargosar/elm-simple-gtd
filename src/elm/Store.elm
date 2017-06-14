port module Store
    exposing
        ( onChange
        , Store
        , generator
        , insert
        , findById
        , findBy
        , mapDocs
        , rejectDocs
        , asIdDict
        , isEmpty
        , filterDocs
        , updateAll
        , findAndUpdateAll
        , upsertOnPouchDBChange
        , upsertInPouchDbOnFirebaseChange
        , persist
        , UpdateAllReturn
        , ChangeList
        )

import Dict exposing (Dict)
import Dict.Extra
import Document exposing (Document, Id)
import Ext.Debug
import Ext.List as List
import Ext.Random as Random
import Ext.Record as Record exposing (get, over, overT2)
import Firebase exposing (DeviceId)
import Toolkit.Helpers exposing (..)
import Toolkit.Operators exposing (..)
import Ext.Function exposing (..)
import Ext.Function.Infix exposing (..)
import List.Extra as List
import Maybe.Extra as Maybe
import Json.Decode as D exposing (Decoder)
import Json.Decode.Pipeline as D
import Json.Encode as E
import Json.Decode as J exposing (Decoder)
import Json.Decode.Pipeline as J
import Json.Encode as J
import Random.Pcg as Random exposing (Seed)
import Set exposing (Set)
import Time exposing (Time)
import Tuple2


port pouchDBUpsert : ( String, String, D.Value ) -> Cmd msg


port pouchDBChanges : (( String, D.Value ) -> msg) -> Sub msg


onChange =
    uncurry >> pouchDBChanges


decodeList : Decoder (Document x) -> List E.Value -> List (Document x)
decodeList decoder =
    List.map (D.decodeValue decoder)
        >> List.filterMap
            (\result ->
                case result of
                    Ok project ->
                        Just project

                    Err x ->
                        let
                            _ =
                                Debug.log "Error while decoding Project" x
                        in
                            Nothing
            )


type alias Store x =
    { seed : Seed
    , dict : Dict Document.Id (Document x)
    , otherFieldsEncoder : Document x -> List ( String, E.Value )
    , decoder : Decoder (Document x)
    , name : String
    , deviceId : DeviceId
    }


dict =
    Record.init .dict (\s b -> { b | dict = s })


type alias OtherFieldsEncoder x =
    Document x -> List ( String, E.Value )


generator :
    String
    -> OtherFieldsEncoder x
    -> Decoder (Document x)
    -> DeviceId
    -> List E.Value
    -> Random.Generator (Store x)
generator name otherFieldsEncoder decoder deviceId encodedList =
    Random.mapWithIndependentSeed
        (\seed ->
            { seed = seed
            , dict =
                decodeList decoder encodedList
                    .|> apply2 ( Document.getId, identity )
                    |> Dict.fromList
            , name = name
            , otherFieldsEncoder = otherFieldsEncoder
            , decoder = decoder
            , deviceId = deviceId
            }
        )


upsertIn store doc =
    pouchDBUpsert ( store.name, doc.id, Document.encode store.otherFieldsEncoder doc )


encode : Document x -> Store x -> E.Value
encode doc s =
    Document.encode s.otherFieldsEncoder doc


persist : Store x -> ( Store x, Cmd msg )
persist s =
    let
        dirtyList =
            filterDocs .dirty s

        ns =
            over dict (Dict.map (\id d -> { d | dirty = False })) s

        cmds =
            dirtyList .|> upsertIn s
    in
        ns ! cmds


replaceDoc doc =
    let
        newDoc =
            { doc | dirty = True }
    in
        Dict.insert (Document.getId newDoc) newDoc


replaceDocIn =
    flip replaceDoc


getUpdateFnDecorator updateFn now store =
    updateFn >> Document.setModifiedAt now >> Document.setDeviceId store.deviceId


type alias Change x =
    ( Document x, Document x )


type alias ChangeList x =
    List (Change x)


type alias UpdateReturn x =
    ( Change x, Store x )


type alias UpdateAllReturn x =
    ( ChangeList x, Store x )


type alias UpdateAllReturnF x =
    UpdateAllReturn x -> UpdateAllReturn x


updateAll :
    Set Document.Id
    -> Time
    -> (Document x -> Document x)
    -> Store x
    -> UpdateAllReturn x
updateAll idSet =
    findAndUpdateAll (Document.getId >> Set.member # idSet)


findAndUpdateAll :
    (Document x -> Bool)
    -> Time
    -> (Document x -> Document x)
    -> Store x
    -> UpdateAllReturn x
findAndUpdateAll pred now updateFn_ store =
    let
        updateFn =
            (getUpdateFnDecorator updateFn_ now store)

        updateAndCollectChanges =
            (\id oldDoc ( changeList, dict ) ->
                let
                    newDoc =
                        updateFn oldDoc
                in
                    -- todo: replace doc actually marks it dirty so we need to get new doc from that function.
                    ( ( oldDoc, newDoc ) :: changeList, replaceDocIn dict newDoc )
            )
    in
        store
            |> overT2 dict
                (\dict ->
                    dict
                        |> Dict.filter (\id doc -> pred doc)
                        |> Dict.foldl updateAndCollectChanges ( [], dict )
                )


decode : D.Value -> Store x -> Maybe (Document x)
decode encodedDoc store =
    D.decodeValue store.decoder encodedDoc
        |> Result.mapError (Debug.log ("Store " ++ store.name))
        |> Result.toMaybe


upsertInPouchDbOnFirebaseChange : D.Value -> Store x -> Cmd msg
upsertInPouchDbOnFirebaseChange jsonValue store =
    decode jsonValue store
        ?|> upsertIn store
        ?= Cmd.none


upsertOnPouchDBChange : D.Value -> Store x -> Maybe ( Document x, Store x )
upsertOnPouchDBChange encodedDoc store =
    decode encodedDoc store
        ?|> (\doc -> ( doc, insertDocInDict doc store ))


updateExternalHelp newDoc store =
    let
        id =
            Document.getId newDoc

        merge oldDoc =
            let
                mergedDoc =
                    1
            in
                store

        add =
            insertDocInDict newDoc store
    in
        findById id store
            ?|> merge
            ?= add


generate : Random.Generator (Document x) -> Store x -> ( Document x, Store x )
generate generator m =
    Random.step generator (getSeed m)
        |> Tuple.mapSecond (setSeed # m)


insert : (DeviceId -> Id -> Document x) -> Store x -> ( Document x, Store x )
insert constructor store =
    Random.mapWithIdGenerator (constructor store.deviceId)
        |> (generate # store)
        |> (\( doc, store ) ->
                let
                    newDoc =
                        { doc | dirty = True }
                in
                    ( newDoc, insertDocInDict newDoc store )
           )


insertDocInDict : Document x -> Store x -> Store x
insertDocInDict doc =
    over dict (Dict.insert (Document.getId doc) doc)


mapDocs fn =
    get dict >> Dict.map (\id doc -> fn doc) >> Dict.values


filterDocs fn =
    get dict >> Dict.filter (\id doc -> fn doc) >> Dict.values


rejectDocs fn =
    filterDocs (fn >> not)


findBy : (Document x -> Bool) -> Store x -> Maybe (Document x)
findBy predicate =
    get dict >> Dict.values >> List.find predicate


findById : Document.Id -> Store x -> Maybe (Document x)
findById id =
    get dict >> Dict.get id


getSeed =
    (.seed)


setSeed seed model =
    { model | seed = seed }


updateSeed updater model =
    setSeed (updater model) model


isEmpty =
    get dict >> Dict.isEmpty


asIdDict =
    get dict


setDict dict model =
    { model | dict = dict }


setDictIn =
    flip setDict
