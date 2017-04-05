port module PouchDB exposing (..)

import Json.Decode as D exposing (Decoder)
import Json.Decode.Pipeline as D
import Json.Encode as E
import Random.Pcg as Random exposing (Seed)
import List.Extra as List
import Time exposing (Time)
import Toolkit.Helpers exposing (..)
import Toolkit.Operators exposing (..)


port onPouchDBBulkDocksResponse : (D.Value -> msg) -> Sub msg



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
    { moreFields | id : Id, rev : Revision }


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


type alias Store model =
    { seed : Seed, list : List model }


init list seed =
    { seed = seed, list = list }


prepend : model -> Store model -> Store model
prepend model =
    updateList (getList >> (::) model)


map fn =
    getList >> List.map fn


findBy predicate =
    getList >> List.find predicate


findById id =
    findBy (.id >> (==) id)


addFromTuple : ( model, Store model ) -> ( model, Store model )
addFromTuple =
    apply2 ( Tuple.first, uncurry prepend )


createAndAdd : Random.Generator model -> Store model -> ( model, Store model )
createAndAdd generator =
    generate generator >> addFromTuple


getSeed =
    (.seed)


setSeed seed model =
    { model | seed = seed }


updateSeed updater model =
    setSeed (updater model) model


getList : Store model -> List model
getList =
    (.list)


setList list model =
    { model | list = list }


updateList : (Store model -> List model) -> Store model -> Store model
updateList updater model =
    setList (updater model) model


generate : Random.Generator model -> Store model -> ( model, Store model )
generate generator m =
    Random.step generator (getSeed m)
        |> Tuple.mapSecond (setSeed # m)
