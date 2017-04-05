port module PouchDB exposing (..)

import Json.Decode as D exposing (Decoder)
import Json.Decode.Pipeline as D
import Json.Encode as E
import Port exposing (Tracker)
import Random.Pcg as Random exposing (Seed)
import List.Extra as List
import Time exposing (Time)
import Toolkit.Helpers exposing (..)
import Toolkit.Operators exposing (..)
import Ext.Function exposing (..)
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
    { moreFields | id : Id, rev : Revision, dirty : Bool }


type alias HasTimeStamps otherFields =
    { otherFields | createdAt : Time, modifiedAt : Time }


documentFieldsDecoder : Decoder (Id -> Revision -> otherFields) -> Decoder otherFields
documentFieldsDecoder =
    D.required "_id" D.string
        >> D.required "_rev" D.string


timeStampFieldsDecoder : Decoder (Time -> Time -> otherFields) -> Decoder otherFields
timeStampFieldsDecoder =
    D.optional "createdAt" (D.float) 0
        >> D.optional "modifiedAt" (D.float) 0


type alias Store x =
    { seed : Seed
    , list : List (Document x)
    , encoder : Document x -> E.Value
    , name : String
    }


init name encoder list seed =
    { seed = seed
    , list = list
    , name = name
    , encoder = encoder
    }


prepend : Document x -> Store x -> Store x
prepend model =
    updateList (getList >> (::) model)


map fn =
    getList >> List.map fn


findBy predicate =
    getList >> List.find predicate


findById id =
    findBy (.id >> (==) id)


addFromTuple : ( Document x, Store x ) -> ( Document x, Store x )
addFromTuple =
    apply2 ( Tuple.first, uncurry prepend )


insert : Random.Generator (Document x) -> Store x -> Store x
insert =
    generate >>> (\( d, s ) -> prepend { d | dirty = True } s)


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


getList : Store x -> List (Document x)
getList =
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
