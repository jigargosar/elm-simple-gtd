module Types exposing (..)

import CmdExtra
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
import TodoMsg exposing (TodoMsg)


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


type alias Return =
    Return.Return Msg Model


type alias ReturnF =
    Return -> Return


type EditModeMsg
    = AddTodoClicked
    | NewTodoTextChanged String
    | NewTodoBlur
    | NewTodoKeyUp String KeyboardEvent
    | StartEditingTodo Todo
    | EditTodoTextChanged String
    | EditTodoBlur Todo
    | EditTodoKeyUp Todo KeyboardEvent


onNewTodo =
    { startAdding = AddTodoClicked |> OnEditModeMsg
    , input = NewTodoTextChanged >> OnEditModeMsg
    , blur = NewTodoBlur |> OnEditModeMsg
    , keyUp = NewTodoKeyUp >>> OnEditModeMsg
    }


startEditingTodo =
    StartEditingTodo >> OnEditModeMsg


onEditTodo =
    { startEditing = startEditingTodo
    , input = EditTodoTextChanged >> OnEditModeMsg
    , blur = EditTodoBlur >> OnEditModeMsg
    , keyUp = EditTodoKeyUp >>> OnEditModeMsg
    }


toggleDone =
    TodoMsg.toggleDone >> OnTodoMsg


markDone =
    TodoMsg.markDone >> OnTodoMsg


toggleDelete =
    TodoMsg.toggleDelete >> OnTodoMsg


setGroup group =
    TodoMsg.setGroup group >> OnTodoMsg


setText text =
    TodoMsg.setText text >> OnTodoMsg


saveNewTodo =
    TodoMsg.saveNewTodo >> OnTodoMsg


splitNewTodoFrom =
    TodoMsg.splitNewTodoFrom >> OnTodoMsg


start =
    TodoMsg.start >> OnTodoMsg


stop =
    OnTodoMsg TodoMsg.stop


stopAndMarkDone =
    OnTodoMsg TodoMsg.StopAndMarkDone


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
    CmdExtra.toCmds OnMsgList


toCmd : msg -> Cmd msg
toCmd =
    CmdExtra.toCmd
