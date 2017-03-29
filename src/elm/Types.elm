module Types exposing (..)

import Ext.Cmd
import KeyboardExtra exposing (KeyboardEvent)
import Return
import RunningTodoDetails exposing (RunningTodoDetails)
import Random.Pcg exposing (Seed)
import Time exposing (Time)
import Todo exposing (Todo, TodoGroup, TodoList)
import Toolkit.Helpers exposing (..)
import Toolkit.Operators exposing (..)
import FunctionExtra exposing (..)
import FunctionExtra.Operators exposing (..)
import Msg.TodoMsg exposing (TodoMsg)


type MainViewType
    = AllByGroupView
    | GroupView TodoGroup
    | DoneView
    | BinView


defaultViewType =
    AllByGroupView


type EditMode
    = EditNewTodoMode String
    | EditTodoMode Todo
    | NotEditing


type alias Model =
    { now : Time
    , todoList : TodoList
    , editMode : EditMode
    , mainViewType : MainViewType
    , seed : Seed
    , runningTodoDetails : Maybe RunningTodoDetails
    }


type alias ModelF =
    Model -> Model


type EditModeMsg
    = AddTodoClicked
    | NewTodoTextChanged String
    | NewTodoBlur
    | NewTodoKeyUp String KeyboardEvent
    | StartEditingTodo Todo
    | EditTodoTextChanged String
    | EditTodoBlur Todo
    | EditTodoKeyUp Todo KeyboardEvent


startAddingTodo =
    AddTodoClicked |> OnEditModeMsg


onNewTodoInput =
    NewTodoTextChanged >> OnEditModeMsg


onNewTodoBlur =
    NewTodoBlur |> OnEditModeMsg


onNewTodoKeyUp =
    NewTodoKeyUp >>> OnEditModeMsg


startEditingTodo =
    StartEditingTodo >> OnEditModeMsg


onEditTodoInput =
    EditTodoTextChanged >> OnEditModeMsg


onEditTodoBlur =
    EditTodoBlur >> OnEditModeMsg


onEditTodoKeyUp =
    EditTodoKeyUp >>> OnEditModeMsg


toggleDone =
    Msg.TodoMsg.toggleDone >> OnTodoMsg


markDone =
    Msg.TodoMsg.markDone >> OnTodoMsg


toggleDelete =
    Msg.TodoMsg.toggleDelete >> OnTodoMsg


setGroup group =
    Msg.TodoMsg.setGroup group >> OnTodoMsg


setText text =
    Msg.TodoMsg.setText text >> OnTodoMsg


saveNewTodo =
    Msg.TodoMsg.saveNewTodo >> OnTodoMsg


splitNewTodoFrom =
    Msg.TodoMsg.splitNewTodoFrom >> OnTodoMsg


start =
    Msg.TodoMsg.start >> OnTodoMsg


stop =
    OnTodoMsg Msg.TodoMsg.stop


stopAndMarkDone =
    OnTodoMsg Msg.TodoMsg.MarkRunningTodoDone


type Msg
    = NoOp
    | OnEditModeMsg EditModeMsg
      --
    | OnTodoMsg TodoMsg
    | SetMainViewType MainViewType
    | OnUpdateNow Time
    | OnMsgList (List Msg)


toCmds : List Msg -> Cmd Msg
toCmds =
    Ext.Cmd.toCmds OnMsgList


toCmd : msg -> Cmd msg
toCmd =
    Ext.Cmd.toCmd


type alias Return =
    Return.Return Msg Model


type alias ReturnF =
    Return -> Return
