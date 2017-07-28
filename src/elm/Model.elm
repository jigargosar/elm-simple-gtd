module Model exposing (..)

import ExclusiveMode.Types exposing (ExclusiveMode(..), SyncForm)
import Toolkit.Operators exposing (..)
import X.Record exposing (..)


now =
    fieldLens .now (\s b -> { b | now = s })


getRemoteSyncForm model =
    let
        maybeForm =
            case model.editMode of
                XMCustomSync form ->
                    Just form

                _ ->
                    Nothing
    in
    maybeForm ?= { uri = model.pouchDBRemoteSyncURI }
