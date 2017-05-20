module Msg exposing (..)

import CommonMsg
import Context
import Document
import Dom
import EditMode
import Ext.Cmd
import Ext.Keyboard as Keyboard exposing (KeyboardEvent)
import Model exposing (..)
import Project
import ReminderOverlay
import Return
import Random.Pcg exposing (Seed)
import Time exposing (Time)
import Todo
import Todo.Form
import Todo.NewForm
import Todo.ReminderForm
import Toolkit.Helpers exposing (..)
import Toolkit.Operators exposing (..)
import Ext.Function exposing (..)
import Ext.Function.Infix exposing (..)
import Firebase
import Json.Decode as D exposing (Decoder)
import Json.Decode.Pipeline as D
import Json.Encode as E


type alias PrevNextIdPair =
    ( Document.Id, Document.Id )


type Msg
    = OnCommonMsg CommonMsg.Msg
    | OnPouchDBChange String D.Value
    | OnFirebaseChange String D.Value
    | OnUserChanged Firebase.User
    | OnFCMTokenChanged Firebase.FCMToken
    | SignIn
    | SignOut
    | RemotePouchSync EditMode.SyncForm
    | TodoAction Todo.UpdateAction Todo.Id
    | ReminderOverlayAction ReminderOverlay.Action
    | OnNotificationClicked TodoNotificationEvent
    | ToggleShowDeletedEntity
    | ToggleDrawer
    | OnLayoutNarrowChanged Bool
    | ToggleTodoDone Todo.Model
    | SetTodoContext Context.Model Todo.Model
    | SetTodoProject Project.Model Todo.Model
    | NewTodo
    | NewProject
    | NewContext
    | NewTodoTextChanged Todo.Text
    | DeactivateEditingMode
    | NewTodoKeyUp KeyboardEvent
    | StartEditingReminder Todo.Model
    | StartEditingContext Todo.Model
    | StartEditingProject Todo.Model
    | SaveCurrentForm
    | FocusPaperInput String
    | AutoFocusPaperInput
    | UpdateRemoteSyncFormUri EditMode.SyncForm String
    | UpdateTodoForm Todo.Form.Model Todo.Form.Action
    | UpdateReminderForm Todo.ReminderForm.Model Todo.ReminderForm.Action
    | OnEntityListKeyDown (List Entity) KeyboardEvent
    | SetView ViewType
    | SetGroupByView GroupByViewType
    | ShowReminderOverlayForTodoId Todo.Id
    | OnNowChanged Time
    | OnMsgList (List Msg)
    | OnKeyboardMsg Keyboard.Msg
    | OnGlobalKeyUp Keyboard.Key
    | OnEntityAction Entity EntityAction
    | StartAddingNewEntity EntityType


toCmds : List Msg -> Cmd Msg
toCmds =
    Ext.Cmd.toCmds OnMsgList


toCmd : msg -> Cmd msg
toCmd =
    Ext.Cmd.toCmd


commonMsg : CommonMsg.Helper Msg
commonMsg =
    CommonMsg.createHelper OnCommonMsg
