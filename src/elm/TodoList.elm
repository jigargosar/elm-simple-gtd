module TodoList exposing (..)

import Main.Model exposing (Model)
import Return exposing (Return)
import Time exposing (Time)
import Todo exposing (TodoGroup, TodoId)
import Toolkit.Helpers exposing (..)
import Toolkit.Operators exposing (..)
import FunctionExtra exposing (..)
import Main.TodoListMsg exposing (..)


update : TodoListMsg -> Model -> Return msg Model
update msg =
    Return.singleton
        >> case msg of
            UpdateTodoAt actionAt ->
                identity

            UpdateTodo action ->
                identity
