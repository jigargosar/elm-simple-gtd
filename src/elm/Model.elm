module Model exposing (..)

import CommonMsg
import ExclusiveMode.Types exposing (ExclusiveMode(..), SyncForm)
import Msg exposing (..)
import X.Record exposing (maybeOver, maybeOverT2, maybeSetIn, over, overReturn, overT2, set)
import Time exposing (Time)
import Toolkit.Operators exposing (..)
import ReturnTypes exposing (..)
import Types exposing (..)


commonMsg : CommonMsg.Helper AppMsg
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
    X.Record.fieldLens .appDrawerModel (\s b -> { b | appDrawerModel = s })


now =
    X.Record.fieldLens .now (\s b -> { b | now = s })


focusInEntity =
    X.Record.fieldLens .focusInEntity (\s b -> { b | focusInEntity = s })


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



-- Focus Functions


setDomFocusToFocusInEntityCmd =
    (commonMsg.focus ".entity-list .focusable-list-item[tabindex=0]")
