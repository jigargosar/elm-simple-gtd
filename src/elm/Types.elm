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
    AddTodoClicked


onNewTodoInput =
    NewTodoTextChanged


onNewTodoBlur =
    NewTodoBlur


onNewTodoKeyUp =
    NewTodoKeyUp


startEditingTodo =
    StartEditingTodo


onEditTodoInput =
    EditTodoTextChanged


onEditTodoBlur =
    EditTodoBlur


onEditTodoKeyUp =
    EditTodoKeyUp


toggleDone =
    TodoMsg.ToggleDone


markDone =
    TodoMsg.markDone


toggleDelete =
    TodoMsg.toggleDelete


setGroup group =
    TodoMsg.setGroup group


setText text =
    TodoMsg.setText text


saveNewTodo =
    TodoMsg.saveNewTodo


splitNewTodoFrom =
    TodoMsg.splitNewTodoFrom


start =
    TodoMsg.start


stop =
    TodoMsg.stop


stopAndMarkDone =
    TodoMsg.MarkRunningTodoDone


type Msg
    = OnTodoMsg TodoMsg
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
