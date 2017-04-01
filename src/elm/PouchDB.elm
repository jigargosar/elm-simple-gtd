port module PouchDB exposing (..)

import Json.Decode as D exposing (Decoder)
import Json.Decode.Pipeline as D
import Json.Encode as E
import Time exposing (Time)


port onPouchDBBulkDocksResponse : (D.Value -> msg) -> Sub msg



-- COMMANDS
--port pouchDBBulkDocks : ( String, List D.Value ) -> Cmd msg


port pouchDBUpsert : ( String, String, D.Value ) -> Cmd msg



--pouchDBBulkDocsHelp : String -> List D.Value -> Cmd msg
--pouchDBBulkDocsHelp dbName list =
--    list
--        |> (curry pouchDBBulkDocks) dbName


encodeAsSetting key value =
    E.object
        [ ( "_id", key |> E.string )
        , ( "value", value )
        ]


pouchDBPersistSetting key value =
    pouchDBUpsert ( "settings", key, value )


type alias Id =
    String


type alias Revision =
    String

defaultRevision =
    ""


type alias Document moreFields =
    { moreFields | id : Id, rev : Revision }


type alias WithTimeStamps otherFields =
    { otherFields | createdAt : Time, modifiedAt : Time }


documentFieldsDecoder : Decoder (Id -> Revision -> otherFields) -> Decoder otherFields
documentFieldsDecoder =
    D.required "_id" D.string
        >> D.required "_rev" D.string


timeStampFieldsDecoder : Decoder (Time -> Time -> otherFields) -> Decoder otherFields
timeStampFieldsDecoder =
    D.optional "createdAt" (D.float) 0
        >> D.optional "modifiedAt" (D.float) 0
