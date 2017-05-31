port module Store
    exposing
        ( onChange
        , Store
        , generator
        , insert
        , findById
        , findBy
        , map
        , reject
        , asIdDict
        , asList
        , filter
        , updateAllDocs
        , updateAllT2
        , findAndUpdateT
        , findAllByIdSetIn
        , upsertOnPouchDBChange
        , upsertInPouchDbOnFirebaseChange
        , persist
        )

import Dict
import Dict.Extra
import Document exposing (Document, Id)
import Ext.Debug
import Ext.List as List
import Ext.Random as Random
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


init name otherFieldsEncoder decoder deviceId encodedList seed =
    { seed = seed
    , list = decodeList decoder encodedList
    , name = name
    , otherFieldsEncoder = otherFieldsEncoder
    , decoder = decoder
    , deviceId = deviceId
    }


generator :
    String
    -> (Document x -> List ( String, E.Value ))
    -> Decoder (Document x)
    -> DeviceId
    -> List E.Value
    -> Random.Generator (Store x)
generator name otherFieldsEncoder decoder deviceId encodedList =
    init name otherFieldsEncoder decoder deviceId encodedList |> Random.mapWithIndependentSeed



--upsert : String -> (Document x -> List ( String, E.Value )) -> Document x -> Cmd msg


upsertIn store doc =
    pouchDBUpsert ( store.name, doc.id, Document.encode store.otherFieldsEncoder doc )


encode : Document x -> Store x -> E.Value
encode doc s =
    Document.encode s.otherFieldsEncoder doc


persist s =
    let
        dirtyList =
            s.list
                |> List.filter .dirty

        ns =
            s.list .|> (\d -> { d | dirty = False }) |> setList # s

        cmds =
            dirtyList .|> upsertIn s
    in
        ns ! cmds


replaceDoc : Document x -> Store x -> Store x
replaceDoc doc s =
    let
        newDoc =
            { doc | dirty = True }
    in
        List.replaceIf (Document.equalById doc) (newDoc) s.list
            |> (setList # s)


replaceDocIn =
    flip replaceDoc


findAndUpdateT :
    (Document x -> Bool)
    -> Time
    -> (Document x -> Document x)
    -> Store x
    -> Maybe ( Document x, Store x )
findAndUpdateT findFn now updateFn store =
    findBy findFn store
        ?+> (getUpdateFnDecorator updateFn now store
                >> apply2 ( Document.getId, replaceDocIn store )
                >> (\( id, store ) -> findById id store ?|> (\doc -> ( doc, store )))
            )


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


updateT2 :
    Time
    -> (Document x -> Document x)
    -> Document.Id
    -> Store x
    -> Maybe (UpdateReturn x)
updateT2 now updateFn id store =
    updateT2Help (getUpdateFnDecorator updateFn now store) id store


updateT2Help :
    (Document x -> Document x)
    -> Document.Id
    -> Store x
    -> Maybe (UpdateReturn x)
updateT2Help updateFn id store =
    findById id store
        ?|> apply2 ( identity, updateFn )
        >> apply2 ( identity, Tuple.second >> replaceDocIn store )


updateAllT2 :
    Set Document.Id
    -> Time
    -> (Document x -> Document x)
    -> Store x
    -> UpdateAllReturn x
updateAllT2 idSet now updateFn store =
    let
        updateAndCollectChanges : Id -> UpdateAllReturnF x
        updateAndCollectChanges =
            (\id (( list, store ) as acc) ->
                updateT2 now updateFn id store
                    ?|> Tuple.mapFirst (List.prependIn list)
                    ?= acc
            )
    in
        Set.foldl updateAndCollectChanges ( [], store ) idSet


updateAllDocs :
    Set Document.Id
    -> Time
    -> (Document x -> Document x)
    -> Store x
    -> Store x
updateAllDocs idSet now updateFn store =
    let
        updateAndSetModifiedAt =
            getUpdateFnDecorator updateFn now store
    in
        idSet |> Set.foldl (updateAllDocHelp # updateAndSetModifiedAt) store


updateAllDocHelp id updateDocFn store =
    findById id store
        ?|> updateDocFn
        >> replaceDocIn store
        ?= store


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


upsertOnPouchDBChange : D.Value -> Store x -> Store x
upsertOnPouchDBChange encodedDoc store =
    decode encodedDoc store ?|> upsertDocOnPouchDBChange # store ?= store


upsertDocOnPouchDBChange doc store =
    asIdDict store
        |> Dict.insert (Document.getId doc) doc
        |> Dict.values
        |> (setList # store)


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
            prepend newDoc store
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
                    ( newDoc, prepend newDoc store )
           )


type alias Store x =
    { seed : Seed
    , list : List (Document x)
    , otherFieldsEncoder : Document x -> List ( String, E.Value )
    , decoder : Decoder (Document x)
    , name : String
    , deviceId : DeviceId
    }


prepend : Document x -> Store x -> Store x
prepend model =
    updateList (asList >> (::) model)


map fn =
    asList >> List.map fn


filter fn =
    asList >> List.filter fn


findAllByIdSetIn store idSet =
    asIdDict store |> Dict.Extra.keepOnly idSet |> Dict.values


reject fn =
    asList >> Ext.Function.reject fn


findBy : (Document x -> Bool) -> Store x -> Maybe (Document x)
findBy predicate =
    asList >> List.find predicate


findById : Document.Id -> Store x -> Maybe (Document x)
findById id =
    findBy (Document.hasId id)


getSeed =
    (.seed)


setSeed seed model =
    { model | seed = seed }


updateSeed updater model =
    setSeed (updater model) model


asList : Store x -> List (Document x)
asList =
    (.list)


asIdDict =
    map (apply2 ( Document.getId, identity )) >> Dict.fromList


setList list model =
    { model | list = list }


updateList : (Store x -> List (Document x)) -> Store x -> Store x
updateList updater model =
    setList (updater model) model
