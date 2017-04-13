port module PouchDB exposing (..)

import Ext.Random as Random
import Json.Decode as D exposing (Decoder)
import Json.Decode.Pipeline as D
import Json.Encode as E
import Port exposing (Tracker)
import Random.Pcg as Random exposing (Seed)
import List.Extra as List
import Time exposing (Time)
import Toolkit.Helpers exposing (..)
import Toolkit.Operators exposing (..)
import Ext.Function as Function exposing (..)
import Ext.Function.Infix exposing (..)
import Tuple2


--port onPouchDBBulkDocksResponse : (D.Value -> msg) -> Sub msg
-- COMMANDS
--port pouchDBBulkDocks : ( String, List D.Value ) -> Cmd msg


port pouchDBUpsert : ( String, String, D.Value ) -> Cmd msg


upsert : String -> (Document x -> E.Value) -> Document x -> Cmd msg
upsert dbName encoder doc =
    pouchDBUpsert ( dbName, doc.id, encoder doc )


type alias Id =
    String


type alias Revision =
    String


defaultRevision =
    ""


type alias Document moreFields =
    { moreFields
        | id : Id
        , rev : Revision
        , dirty : Bool
        , deleted : Bool
        , createdAt : Time
        , modifiedAt : Time
    }


documentFieldsDecoder : Decoder (Id -> Revision -> Time -> Time -> Bool -> otherFields) -> Decoder otherFields
documentFieldsDecoder =
    D.required "_id" D.string
        >> D.required "_rev" D.string
        >> D.optional "createdAt" (D.float) 0
        >> D.optional "modifiedAt" (D.float) 0
        >> D.optional "deleted" D.bool False


type alias Store x =
    { seed : Seed
    , list : List (Document x)
    , encoder : Document x -> E.Value
    , decoder : Decoder (Document x)
    , name : String
    }


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


init name encoder decoder encodedList seed =
    { seed = seed
    , list = decodeList decoder encodedList
    , name = name
    , encoder = encoder
    , decoder = decoder
    }


generator name encoder decoder encodedList =
    init name encoder decoder encodedList |> Random.mapWithIndependentSeed


prepend : Document x -> Store x -> Store x
prepend model =
    updateList (asList >> (::) model)


map fn =
    asList >> List.map fn


filter fn =
    asList >> List.filter fn


reject fn =
    asList >> Function.reject fn


findBy predicate =
    asList >> List.find predicate


findById id =
    findBy (.id >> (==) id)


addFromTuple : ( Document x, Store x ) -> ( Document x, Store x )
addFromTuple =
    apply2 ( Tuple.first, uncurry prepend )


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


update : Document x -> Store x -> Store x
update doc s =
    let
        newDoc =
            { doc | dirty = True }
    in
        List.replaceIf (\d2 -> d2.id == doc.id) (newDoc) s.list
            |> (setList # s)


generate : Random.Generator (Document x) -> Store x -> ( Document x, Store x )
generate generator m =
    Random.step generator (getSeed m)
        |> Tuple.mapSecond (setSeed # m)


persist s =
    let
        dirtyList =
            s.list
                |> List.filter .dirty

        ns =
            s.list .|> (\d -> { d | dirty = False }) |> setList # s

        cmds =
            dirtyList .|> upsert s.name s.encoder
    in
        ns ! cmds


getSeed =
    (.seed)


setSeed seed model =
    { model | seed = seed }


updateSeed updater model =
    setSeed (updater model) model


asList : Store x -> List (Document x)
asList =
    (.list)


setList list model =
    { model | list = list }


updateList : (Store x -> List (Document x)) -> Store x -> Store x
updateList updater model =
    setList (updater model) model


type alias TT msg =
    Tracker {} {} msg


createTracker : TT msg
createTracker =
    Port.init (\req -> ping req)


port ping : { portRequestId : Int } -> Cmd msg


port pong : ({ portRequestId : Int } -> msg) -> Sub msg


tt =
    createTracker


test : ( TT msg, Cmd msg )
test =
    Port.call { portRequestId = 0 } (\res -> Cmd.none) tt
