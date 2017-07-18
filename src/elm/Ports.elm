port module Ports exposing (..)

import Json.Encode as E


port onFirebaseDatabaseChange : (( String, E.Value ) -> msg) -> Sub msg


onFirebaseDatabaseChangeSub tagger =
    onFirebaseDatabaseChange (uncurry tagger)
