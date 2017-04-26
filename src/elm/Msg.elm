module Msg exposing (..)

import Context
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
import Todo.ReminderForm
import Toolkit.Helpers exposing (..)
import Toolkit.Operators exposing (..)
import Ext.Function exposing (..)
import Ext.Function.Infix exposing (..)
import Types exposing (..)


type Msg
    = NoOp
    | RemotePouchSync
    | TodoAction Todo.UpdateAction Todo.Id
    | ReminderOverlayAction ReminderOverlay.Action
    | OnNotificationClicked TodoNotificationEvent
    | ToggleShowDeletedEntity
    | Start Todo.Model
    | Stop
    | MarkRunningTodoDone
    | ToggleTodoDone Todo.Model
    | SetTodoContext Context.Model Todo.Model
    | SetTodoProject Project.Model Todo.Model
    | CreateTodo String
    | CopyAndEditTodo Todo.Model
    | CopyAndEditTodoById Todo.Id
    | StartAddingTodo
    | NewProject
    | NewContext
    | NewTodoTextChanged Todo.Text
    | DeactivateEditingMode
    | NewTodoKeyUp String KeyboardEvent
    | StartEditingTodo Todo.Model
    | StartEditingReminder Todo.ReminderForm.Model
    | SaveEditingEntity
    | FocusPaperInput String
    | AutoFocusPaperInput
    | UpdateTodoForm Todo.Form.Model Todo.Form.Action
    | UpdateReminderForm Todo.ReminderForm.Model Todo.ReminderForm.Action
    | EditTodoFormKeyUp TodoForm KeyboardEvent
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
