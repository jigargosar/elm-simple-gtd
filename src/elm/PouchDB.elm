port module PouchDB exposing (..)

import Json.Decode as D
import Json.Encode as E
import Time exposing (Time)


port onPouchDBBulkDocksResponse : (D.Value -> msg) -> Sub msg



-- COMMANDS


port pouchDBBulkDocks : ( String, List D.Value ) -> Cmd msg


port pouchDBUpsert : ( String, String, D.Value ) -> Cmd msg


pouchDBBulkDocsHelp : String -> List D.Value -> Cmd msg
pouchDBBulkDocsHelp dbName list =
    list
        |> (curry pouchDBBulkDocks) dbName


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


type alias Document moreFields =
    { moreFields | id : Id, rev : Revision }


type alias WithTimeStamps otherFields =
    { otherFields | createdAt : Time, modifiedAt : Time }
