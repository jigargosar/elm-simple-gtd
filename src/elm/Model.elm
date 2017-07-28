module Model exposing (..)

import ExclusiveMode.Types exposing (ExclusiveMode(..), SyncForm)
import Toolkit.Operators exposing (..)
import X.Record exposing (..)


now =
    fieldLens .now (\s b -> { b | now = s })


focusInEntity__ =
    fieldLens .focusInEntity_ (\s b -> { b | focusInEntity_ = s })


getFocusInEntity =
    get focusInEntity__


getRemoteSyncForm model =
    let
        maybeForm =
            case model.editMode of
                XMCustomSync form ->
                    Just form

                _ ->
                    Nothing
    in
    maybeForm ?= createRemoteSyncForm model


createRemoteSyncForm model =
    { uri = model.pouchDBRemoteSyncURI }


getNow =
    .now



-- Focus Functions
