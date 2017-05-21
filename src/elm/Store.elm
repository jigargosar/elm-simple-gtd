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
        , findAndUpdate
        , replaceDoc__
        , findAllByIdSet__
        , updateExternal__
        , upsertEncoded__
        , persist
        )

import Dict
import Document exposing (Document, Id)
import Ext.Debug
import Ext.Random as Random
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


init name otherFieldsEncoder decoder encodedList seed =
    { seed = seed
    , list = decodeList decoder encodedList
    , name = name
    , otherFieldsEncoder = otherFieldsEncoder
    , decoder = decoder
    }


generator : String -> (Document x -> List ( String, E.Value )) -> Decoder (Document x) -> List E.Value -> Random.Generator (Store x)
generator name otherFieldsEncoder decoder encodedList =
    init name otherFieldsEncoder decoder encodedList |> Random.mapWithIndependentSeed



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


replaceDoc__ : Document x -> Store x -> Store x
replaceDoc__ doc s =
    let
        newDoc =
            { doc | dirty = True }
    in
        List.replaceIf (Document.equalById doc) (newDoc) s.list
            |> (setList # s)


replaceDocIn =
    flip replaceDoc__


findAndUpdate findFn now updateFn store =
    findBy findFn store
        ?|> (\doc -> updateFn doc |> replaceDocIn store |> (,) doc)


updateDoc id =
    updateAllDocs (Set.singleton id)


updateAllDocs :
    Set Document.Id
    -> Time
    -> (Document x -> Document x)
    -> Store x
    -> Store x
updateAllDocs idSet now updateFn store =
    let
        updateAndSetModifiedAt =
            updateFn >> Document.setModifiedAt now
    in
        idSet |> Set.foldl (updateDocWithId # updateFn) store


updateDocWithId id updateDocFn store =
    findById id store
        ?|> updateDocFn
        >> replaceDocIn store
        ?= store


decode : D.Value -> Store x -> Maybe (Document x)
decode encodedDoc store =
    D.decodeValue store.decoder encodedDoc
        |> Result.mapError (Debug.log ("Store " ++ store.name))
        |> Result.toMaybe


upsertEncoded__ : D.Value -> Store x -> Cmd msg
upsertEncoded__ jsonValue store =
    decode jsonValue store
        ?|> upsertIn store
        ?= Cmd.none


updateExternal__ : D.Value -> Store x -> Store x
updateExternal__ encodedDoc store =
    decode encodedDoc store ?|> insertExternal # store ?= store


insertExternal doc store =
    {- let
           _ =
               Debug.log "exter doc change adding to store" (doc)
       in
    -}
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


insert : (Id -> Document x) -> Store x -> ( Document x, Store x )
insert constructor s =
    Random.mapWithIdGenerator constructor
        |> (generate # s)
        |> (\( d, s ) ->
                let
                    nd =
                        { d | dirty = True }
                in
                    ( nd, prepend nd s )
           )


type alias Store x =
    { seed : Seed
    , list : List (Document x)
    , otherFieldsEncoder : Document x -> List ( String, E.Value )
    , decoder : Decoder (Document x)
    , name : String
    }


prepend : Document x -> Store x -> Store x
prepend model =
    updateList (asList >> (::) model)


map fn =
    asList >> List.map fn


filter fn =
    asList >> List.filter fn


findAllByIdSet__ idSet store =
    let
        idDict =
            asIdDict store
    in
        idSet |> Set.toList .|> Dict.get # idDict |> List.filterMap identity


reject fn =
    asList >> Ext.Function.reject fn


findBy predicate =
    asList >> List.find predicate


findById id =
    findBy (.id >> (==) id)


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
