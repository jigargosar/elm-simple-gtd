module TodoAction exposing (..)

import Time exposing (Time)
import Todo exposing (TodoGroup, TodoId, TodoText)
import Toolkit.Helpers exposing (..)
import Toolkit.Operators exposing (..)
import FunctionExtra exposing (..)


type EditAction
    = ToggleDone
    | SetGroup TodoGroup
    | SetText String
    | Delete


type TodoActionType
    = Edit EditAction TodoId
    | New TodoText


type alias TodoAction =
    { now : Time, type_ : TodoActionType }


toggleDone : TodoId -> TodoActionType
toggleDone =
    Edit ToggleDone



--
--delete =
--    Edit Delete
--setGroup : TodoGroup -> TodoId -> TodoListMsg
--setGroup =
--    SetGroup >> UpdateTodo
--
--
--setText : String -> TodoId -> TodoListMsg
--setText =
--    SetText >> UpdateTodo
--
--
--addNewTodo : String -> TodoListMsg
--addNewTodo =
--    AddNewTodo
