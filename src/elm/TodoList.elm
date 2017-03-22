module TodoList exposing (..)

import Main.Model exposing (Model)
import Return exposing (Return)
import Time exposing (Time)
import Todo exposing (TodoGroup, TodoId)
import Toolkit.Helpers exposing (..)
import Toolkit.Operators exposing (..)
import FunctionExtra exposing (..)


type ActionType
    = ToggleDone
    | SetGroup TodoGroup
    | Delete


type alias AtTime a =
    { a | at : Time }


type alias Action =
    { id : TodoId
    , actionType : ActionType
    }


type alias ActionAt =
    AtTime Action


type Msg
    = UpdateTodoAt ActionAt
    | UpdateTodo Action


update : Msg -> Model -> Return msg Model
update msg =
    Return.singleton
        >> case msg of
            UpdateTodoAt actionAt ->
                identity

            UpdateTodo action ->
                identity
