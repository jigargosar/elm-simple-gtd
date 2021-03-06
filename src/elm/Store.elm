port module Store
    exposing
        ( Store
        , asIdDict
        , filterDocs
        , findBy
        , findById
        , generator
        , getUpsertInPouchDbOnFirebaseChangeCmd
        , insert
        , insertAndPersist
        , isEmpty
        , mapDocs
        , rejectDocs
        , updateAndPersist
        , upsertInMemoryOnPouchDBChange
        )

import Data.DeviceId exposing (DeviceId)
import Dict exposing (Dict)
import Document exposing (..)
import Json.Decode as D exposing (Decoder)
import Json.Encode as E
import List.Extra as List
import Random.Pcg
import Set exposing (Set)
import Time exposing (Time)
import Toolkit.Helpers exposing (..)
import Toolkit.Operators exposing (..)
import Tuple2
import X.Debug
import X.Random
import X.Record as Record exposing (get, over, overT2)


type alias Store x =
    { seed : Random.Pcg.Seed
    , dict : Dict DocId (Document x)
    , otherFieldsEncoder : Document x -> List ( String, E.Value )
    , decoder : Decoder (Document x)
    , name : String
    , deviceId : DeviceId
    }


port pouchDBUpsert : ( String, String, D.Value ) -> Cmd msg


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
                                X.Debug.log "Error while decoding Project" x
                        in
                        Nothing
            )


dict =
    Record.fieldLens .dict (\s b -> { b | dict = s })


type alias OtherFieldsEncoder x =
    Document x -> List ( String, E.Value )


generator :
    String
    -> OtherFieldsEncoder x
    -> Decoder (Document x)
    -> DeviceId
    -> List E.Value
    -> Random.Pcg.Generator (Store x)
generator name otherFieldsEncoder decoder deviceId encodedList =
    X.Random.mapWithIndependentSeed
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


upsertInCmd store doc =
    pouchDBUpsert ( store.name, doc.id, Document.encode store.otherFieldsEncoder doc )


encode : Document x -> Store x -> E.Value
encode doc s =
    Document.encode s.otherFieldsEncoder doc


replaceDoc doc =
    Dict.insert (Document.getId doc) doc


replaceDocIn =
    flip replaceDoc


getUpdateFnDecorator updateFn now store =
    updateFn >> Document.setModifiedAt now >> Document.setDeviceId store.deviceId


type alias Change x =
    ( Document x, Document x )


type alias ChangeList x =
    List (Change x)


type alias UpdateAllReturn x =
    ( ChangeList x, Store x )


type alias UpdateAllReturnF x =
    UpdateAllReturn x -> UpdateAllReturn x



{-
   updateAll :
       Set DocId
       -> Time
       -> (Document x -> Document x)
       -> Store x
       -> UpdateAllReturn x
   updateAll idSet =
       findAndUpdateAll (Document.getId >> Set.member # idSet)
-}


findAndUpdateAll :
    (Document x -> Bool)
    -> Time
    -> (Document x -> Document x)
    -> Store x
    -> UpdateAllReturn x
findAndUpdateAll pred now updateFn_ store =
    let
        updateFn =
            getUpdateFnDecorator updateFn_ now store

        updateAndCollectChanges =
            \id oldDoc ( changeList, dict ) ->
                let
                    newDoc =
                        updateFn oldDoc
                in
                ( ( oldDoc, newDoc ) :: changeList, replaceDocIn dict newDoc )
    in
    store
        |> overT2 dict
            (\dict ->
                dict
                    |> Dict.filter (\id doc -> pred doc)
                    |> Dict.foldl updateAndCollectChanges ( [], dict )
            )


updateAndPersist pred now updateFn_ store =
    let
        ( result, newStore ) =
            findAndUpdateAll pred now updateFn_ store

        persistCmd =
            result
                |> List.map (Tuple.second >> upsertInCmd store)
                >> Cmd.batch
    in
    ( newStore, persistCmd )


upsertDoc doc store =
    over dict (Dict.insert (Document.getId doc) doc) store
        |> addUpsertDocCmd doc


addUpsertDocCmd doc store =
    ( store, upsertInCmd store doc )


update : DocId -> Time -> (Document x -> Document x) -> Store x -> Maybe ( Store x, Cmd msg )
update id now updateFn store =
    let
        updateHelp doc =
            let
                decoratedUpdateFn =
                    getUpdateFnDecorator updateFn now store
            in
            upsertDoc (decoratedUpdateFn doc) store
    in
    findById id store ?|> updateHelp


updateAll : Set DocId -> Time -> (Document x -> Document x) -> Store x -> ( Store x, Cmd msg )
updateAll idSet now updateFn store =
    idSet
        |> Set.foldl
            (\docId ( store, cmd ) ->
                update docId now updateFn store
                    ?|> Tuple.mapSecond (\newCmd -> Cmd.batch [ cmd, newCmd ])
                    ?= ( store, cmd )
            )
            ( store, Cmd.none )


decode : D.Value -> Store x -> Maybe (Document x)
decode encodedDoc store =
    D.decodeValue store.decoder encodedDoc
        |> Result.mapError (X.Debug.log ("Store " ++ store.name))
        |> Result.toMaybe


getUpsertInPouchDbOnFirebaseChangeCmd : D.Value -> Store x -> Cmd msg
getUpsertInPouchDbOnFirebaseChangeCmd jsonValue store =
    decode jsonValue store
        ?|> upsertInCmd store
        ?= Cmd.none


upsertInMemoryOnPouchDBChange : D.Value -> Store x -> Maybe ( Document x, Store x )
upsertInMemoryOnPouchDBChange encodedDoc store =
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


generate : Random.Pcg.Generator (Document x) -> Store x -> ( Document x, Store x )
generate generator m =
    Random.Pcg.step generator (getSeed m)
        |> Tuple.mapSecond (setSeed # m)


insert : (DeviceId -> DocId -> Document x) -> Store x -> ( Document x, Store x )
insert constructor store =
    X.Random.mapWithIdGenerator (constructor store.deviceId)
        |> (generate # store)
        |> (\( doc, store ) ->
                ( doc, insertDocInDict doc store )
           )


insertAndPersist : (DeviceId -> DocId -> Document x) -> Store x -> ( Store x, Cmd msg )
insertAndPersist constructor store =
    insert constructor store
        |> Tuple2.mapFirst (upsertInCmd store)
        |> Tuple2.swap


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


findById : DocId -> Store x -> Maybe (Document x)
findById id =
    get dict >> Dict.get id


getSeed =
    .seed


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
