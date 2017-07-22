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



--focusInEntity : Field Entity (Types.HasFocusInEntity a)


focusInEntity =
    fieldLens .focusInEntity (\s b -> { b | focusInEntity = s })



--setFocusInEntity : Entity -> Types.HasFocusInEntityF a


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
    .now



-- Focus Functions
