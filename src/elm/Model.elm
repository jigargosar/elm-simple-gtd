module Model exposing (..)

import ExclusiveMode.Types exposing (ExclusiveMode(..), SyncForm)
import Toolkit.Operators exposing (..)
import X.Record exposing (..)


--import Types
--commonMsg : CommonMsg.Helper AppMsg
-- Model Lens


now =
    fieldLens .now (\s b -> { b | now = s })


focusInEntity__ =
    fieldLens .focusInEntity_ (\s b -> { b | focusInEntity_ = s })


setFocusInEntity__ entity =
    set focusInEntity__ entity


getFocusInEntity =
    get focusInEntity__


maybeOverFocusInEntity__ =
    maybeOver focusInEntity__


maybeSetFocusInEntityIn_ model value =
    maybeSet focusInEntity__ value model


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
