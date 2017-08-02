port module Ports exposing (..)

import Json.Encode as E


port pouchDBChanges : (( String, E.Value ) -> msg) -> Sub msg


port onFirebaseDatabaseChange : (( String, E.Value ) -> msg) -> Sub msg


port persistLocalPref : E.Value -> Cmd msg



-- local storage


port persistToLocalStorage : ( String, E.Value ) -> Cmd msg
