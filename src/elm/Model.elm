module Model exposing (..)

import CommonMsg
import Entity.Types exposing (EntityListViewType, Entity)
import ExclusiveMode.Types exposing (ExclusiveMode(..), SyncForm)
import Msg exposing (..)
import Todo.Types exposing (TodoAction(TA_SnoozeTill))
import Types exposing (AppConfig, AppModel, ModelF, ModelReturnF)
import X.Keyboard as Keyboard exposing (KeyboardEvent, KeyboardState)
import X.Record exposing (maybeOver, maybeOverT2, maybeSetIn, over, overReturn, overT2, set)
import Keyboard.Combo exposing (combo1, combo2, combo3)
import Keyboard.Combo as Combo
import Todo.Notification.Model
import List.Extra as List
import Maybe.Extra as Maybe
import X.Function.Infix exposing (..)
import Time exposing (Time)
import Toolkit.Operators exposing (..)


commonMsg : CommonMsg.Helper Msg
commonMsg =
    CommonMsg.createHelper OnCommonMsg


noop =
    commonMsg.noOp


logString =
    commonMsg.logString



-- Model Lens


appDrawerModel =
    X.Record.field .appDrawerModel (\s b -> { b | appDrawerModel = s })


now =
    X.Record.field .now (\s b -> { b | now = s })


focusInEntity =
    X.Record.field .focusInEntity (\s b -> { b | focusInEntity = s })


keyComboModel =
    X.Record.field .keyComboModel (\s b -> { b | keyComboModel = s })


removeReminderOverlay model =
    { model | reminderOverlay = Todo.Notification.Model.none }


setReminderOverlayToSnoozeView details model =
    { model | reminderOverlay = Todo.Notification.Model.snoozeView details }


getMaybeEditTodoReminderForm model =
    case model.editMode of
        XMEditTodoReminder form ->
            Just form

        _ ->
            Nothing


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
