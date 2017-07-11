module Model exposing (..)

import CommonMsg
import ExclusiveMode.Types exposing (ExclusiveMode(..), SyncForm)
import Msg exposing (..)
import Types exposing (AppConfig, AppModel, ModelF, ModelReturnF)
import X.Record exposing (maybeOver, maybeOverT2, maybeSetIn, over, overReturn, overT2, set)
import Time exposing (Time)
import Toolkit.Operators exposing (..)


commonMsg : CommonMsg.Helper Msg
commonMsg =
    CommonMsg.createHelper OnCommonMsg


noop =
    commonMsg.noOp


logString =
    let
        _ =
            2
    in
        commonMsg.logString



-- Model Lens


appDrawerModel =
    X.Record.field .appDrawerModel (\s b -> { b | appDrawerModel = s })


now =
    X.Record.field .now (\s b -> { b | now = s })


focusInEntity =
    X.Record.field .focusInEntity (\s b -> { b | focusInEntity = s })


getRemoteSyncForm model =
    let
        maybeForm =
            case model.editMode of
                XMEditSyncSettings form ->
                    Just form

                _ ->
                    Nothing
    in
        maybeForm ?= createRemoteSyncForm model


createRemoteSyncForm : AppModel -> SyncForm
createRemoteSyncForm model =
    { uri = model.pouchDBRemoteSyncURI }


getNow : AppModel -> Time
getNow =
    (.now)


setNow : Time -> ModelF
setNow now model =
    { model | now = now }



-- Focus Functions


setDomFocusToFocusInEntityCmd =
    (commonMsg.focus ".entity-list .focusable-list-item[tabindex=0]")
