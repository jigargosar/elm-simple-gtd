module Model exposing (..)

import ExclusiveMode.Types exposing (ExclusiveMode(..), SyncForm)
import X.Record exposing (..)
import Toolkit.Operators exposing (..)
import Types


--commonMsg : CommonMsg.Helper AppMsg
-- Model Lens


appDrawerModel =
    fieldLens .appDrawerModel (\s b -> { b | appDrawerModel = s })


now =
    fieldLens .now (\s b -> { b | now = s })


focusInEntity =
    fieldLens .focusInEntity (\s b -> { b | focusInEntity = s })


setFocusInEntity entity =
    set focusInEntity entity


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



--createRemoteSyncForm : AppModel -> SyncForm


createRemoteSyncForm model =
    { uri = model.pouchDBRemoteSyncURI }



--getNow : AppModel -> Time


getNow =
    (.now)



-- Focus Functions
