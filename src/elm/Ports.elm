port module Ports exposing (..)

import Json.Encode as E


port pouchDBChanges : (( String, E.Value ) -> msg) -> Sub msg


port onFirebaseDatabaseChange : (( String, E.Value ) -> msg) -> Sub msg



-- local storage


port persistToOfflineStore : ( String, E.Value ) -> Cmd msg


port debugPort : (String -> msg) -> Sub msg
