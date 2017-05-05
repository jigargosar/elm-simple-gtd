module Msg exposing (..)

import CommonMsg
import Context
import Document
import Dom
import EditMode exposing (TodoForm)
import Ext.Cmd
import Ext.Keyboard as Keyboard exposing (KeyboardEvent)
import Model.Types exposing (..)
import Project
import ReminderOverlay
import Return
import RunningTodo exposing (RunningTodo)
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


type alias PrevNextIdPair =
    ( Document.Id, Document.Id )


type Msg
    = OnCommonMsg CommonMsg.Msg
    | OnFirebaseUserChanged Firebase.User
    | SetFCMToken Firebase.FCMToken
    | Login
    | RemotePouchSync EditMode.RemoteSyncForm
    | SetMainViewFocusedDocumentId Document.Id
    | TodoAction Todo.UpdateAction Todo.Id
    | ReminderOverlayAction ReminderOverlay.Action
    | OnNotificationClicked TodoNotificationEvent
    | ToggleShowDeletedEntity
    | ToggleDrawer
    | Start Todo.Model
    | Stop
    | MarkRunningTodoDone
    | ToggleTodoDone Todo.Model
    | SetTodoContext Context.Model Todo.Model
    | SetTodoProject Project.Model Todo.Model
    | CopyAndEditTodo Todo.Model
    | CopyAndEditTodoById Todo.Id
    | StartAddingTodo
    | NewProject
    | NewContext
    | NewTodoTextChanged Todo.Text
    | DeactivateEditingMode
    | NewTodoKeyUp Todo.NewForm.Model KeyboardEvent
    | StartEditingTodo Todo.Model
    | StartEditingReminder Todo.Model
    | SaveCurrentForm
    | FocusPaperInput String
    | AutoFocusPaperInput
    | UpdateRemoteSyncFormUri EditMode.RemoteSyncForm String
    | UpdateTodoForm Todo.Form.Model Todo.Form.Action
    | UpdateReminderForm Todo.ReminderForm.Model Todo.ReminderForm.Action
    | EditTodoFormKeyUp TodoForm KeyboardEvent
    | OnTestListKeyDown KeyboardEvent
    | OnTodoListKeyDown PrevNextIdPair KeyboardEvent
    | OnTestListItemFocus Int
    | TodoCheckBoxClicked Todo.Model
    | ClearSelection
    | SelectionDoneClicked
    | SelectionEditClicked
    | SelectionTrashClicked
    | SetView MainViewType
    | ShowReminderOverlayForTodoId Todo.Id
    | OnNowChanged Time
    | OnMsgList (List Msg)
    | OnKeyboardMsg Keyboard.Msg
    | OnKeyUp Keyboard.Key
    | OnEntityAction Entity EntityAction


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
