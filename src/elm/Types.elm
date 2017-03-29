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
import Msg.TodoMsg as TodoMsg exposing (TodoMsg(..))


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


startAddingTodo =
    AddTodoClicked |> OnTodoMsg


onNewTodoInput =
    NewTodoTextChanged >> OnTodoMsg


onNewTodoBlur =
    NewTodoBlur |> OnTodoMsg


onNewTodoKeyUp =
    NewTodoKeyUp >>> OnTodoMsg


startEditingTodo =
    StartEditingTodo >> OnTodoMsg


onEditTodoInput =
    EditTodoTextChanged >> OnTodoMsg


onEditTodoBlur =
    EditTodoBlur >> OnTodoMsg


onEditTodoKeyUp =
    EditTodoKeyUp >>> OnTodoMsg


toggleDone =
    TodoMsg.ToggleDone >> OnTodoMsg


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
    OnTodoMsg TodoMsg.MarkRunningTodoDone


type Msg
    = NoOp
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
