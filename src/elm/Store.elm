port module Store exposing (..)

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
import Random.Pcg as Random exposing (Seed)
import Set


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


upsert : String -> (Document x -> List ( String, E.Value )) -> Document x -> Cmd msg
upsert dbName otherFieldsEncoder doc =
    pouchDBUpsert ( dbName, doc.id, Document.encode otherFieldsEncoder doc )


encodeDoc : Document x -> Store x -> E.Value
encodeDoc doc s =
    Document.encode s.otherFieldsEncoder doc


persist s =
    let
        dirtyList =
            s.list
                |> List.filter .dirty

        ns =
            s.list .|> (\d -> { d | dirty = False }) |> setList # s

        cmds =
            dirtyList .|> upsert s.name s.otherFieldsEncoder
    in
        ns ! cmds


update : Document x -> Store x -> Store x
update doc s =
    let
        newDoc =
            { doc | dirty = True }
    in
        List.replaceIf (Document.equalById doc) (newDoc) s.list
            |> (setList # s)


decode encodedDoc store =
    D.decodeValue store.decoder encodedDoc
        |> Result.mapError (Debug.log "Store")
        |> Result.toMaybe


updateExternal : D.Value -> Store x -> Store x
updateExternal encodedDoc store =
    decode encodedDoc store ?|> insertExternal # store ?= store


insertExternal doc store =
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


findAllByIdSet idSet store =
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
