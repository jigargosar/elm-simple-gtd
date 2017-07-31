port module Ports exposing (..)

import Json.Encode as E


port pouchDBChanges : (( String, E.Value ) -> msg) -> Sub msg


port onFirebaseDatabaseChange : (( String, E.Value ) -> msg) -> Sub msg


port persistLocalPref : E.Value -> Cmd msg



-- debug ports


port onDebugAction : (E.Value -> msg) -> Sub msg
