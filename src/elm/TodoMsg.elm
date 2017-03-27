module TodoMsg exposing (..)

import KeyboardExtra exposing (KeyboardEvent)
import Time exposing (Time)
import Todo exposing (Todo, TodoGroup, TodoId)
import Toolkit.Helpers exposing (..)
import Toolkit.Operators exposing (..)
import FunctionExtra exposing (..)
import FunctionExtra.Operators exposing (..)


type NewTodoMsg
    = AddTodoClicked
    | NewTodoTextChanged String
    | NewTodoBlur
    | NewTodoKeyUp String KeyboardEvent


type EditTodoMsg
    = StartEditingTodo Todo
    | EditTodoTextChanged String
    | EditTodoBlur Todo
    | EditTodoKeyUp Todo KeyboardEvent

type EditModeMsg = OnNewTodoMsg NewTodoMsg | OnEditTodoMsg EditTodoMsg

type UpdateAction
    = ToggleDone
    | MarkDone
    | SetGroup TodoGroup
    | SetText String
    | ToggleDelete


type CreateAction
    = FromText String
    | FromId TodoId



--type ActiveTaskAction = Start TodoId | Stop | MarkDone


type RequiresNowAction
    = Update UpdateAction TodoId
    | Create String
    | CopyAndEdit Todo


type TodoMsg
    = Start TodoId
    | Stop
    | StopAndMarkDone
    | OnRequiresNowAction RequiresNowAction
    | OnActionWithNow RequiresNowAction Time
    | OnEditModeMsg EditModeMsg


update =
    Update >>> OnRequiresNowAction


toggleDone =
    update ToggleDone


markDone =
    update MarkDone


toggleDelete =
    update ToggleDelete


setGroup group =
    update (SetGroup group)


setText text =
    update (SetText text)


saveNewTodo =
    Create >> OnRequiresNowAction


splitNewTodoFrom =
    CopyAndEdit >> OnRequiresNowAction


start =
    Start


stop =
    Stop


stopAndMarkDone =
    StopAndMarkDone
