module Model exposing (..)

import ExclusiveMode.Types exposing (ExclusiveMode(..), SyncForm)
import Toolkit.Operators exposing (..)
import X.Record exposing (..)


--import Types
--commonMsg : CommonMsg.Helper AppMsg
-- Model Lens


appDrawerModel =
    fieldLens .appDrawerModel (\s b -> { b | appDrawerModel = s })


now =
    fieldLens .now (\s b -> { b | now = s })


focusInEntity_ =
    fieldLens .focusInEntity_ (\s b -> { b | focusInEntity_ = s })


setFocusInEntity_ entity =
    set focusInEntity_ entity


getFocusInEntity =
    get focusInEntity_


maybeOverFocusInEntity_ =
    maybeOver focusInEntity_


maybeSetFocusInEntityIn_ model value =
    maybeSet focusInEntity_ value model


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
