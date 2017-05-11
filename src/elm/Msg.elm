module Msg exposing (..)

import CommonMsg
import Context
import Document
import Dom
import EditMode
import Ext.Cmd
import Ext.Keyboard as Keyboard exposing (KeyboardEvent)
import Types exposing (..)
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
    | OnExternalEntityChanged String D.Value
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
    | StartAddingTodo
    | NewProject
    | NewContext
    | NewTodoTextChanged Todo.Text
    | DeactivateEditingMode
    | NewTodoKeyUp Todo.NewForm.Model KeyboardEvent
    | StartEditingReminder Todo.Model
    | SaveCurrentForm
    | FocusPaperInput String
    | AutoFocusPaperInput
    | UpdateRemoteSyncFormUri EditMode.SyncForm String
    | UpdateTodoForm Todo.Form.Model Todo.Form.Action
    | UpdateReminderForm Todo.ReminderForm.Model Todo.ReminderForm.Action
    | OnEntityListKeyDown (List Entity) KeyboardEvent
    | SetView MainViewType
    | SetGroupByView GroupByViewType
    | ShowReminderOverlayForTodoId Todo.Id
    | OnNowChanged Time
    | OnMsgList (List Msg)
    | OnKeyboardMsg Keyboard.Msg
    | OnGlobalKeyUp Keyboard.Key
    | OnEntityAction Entity EntityAction
    | OnFocusedEntityAction EntityAction


toCmds : List Msg -> Cmd Msg
toCmds =
    Ext.Cmd.toCmds OnMsgList


toCmd : msg -> Cmd msg
toCmd =
    Ext.Cmd.toCmd


type alias Return =
    Return.Return Msg Model


type alias ReturnTuple a =
    Return.Return Msg ( a, Model )


type alias ReturnF =
    Return -> Return


commonMsg : CommonMsg.Helper Msg
commonMsg =
    CommonMsg.createHelper OnCommonMsg
