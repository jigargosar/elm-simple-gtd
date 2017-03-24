module Main.Types exposing (..)

import Random.Pcg exposing (Seed)
import Time exposing (Time)
import Todo exposing (Todo, TodoList)
import Toolkit.Helpers exposing (..)
import Toolkit.Operators exposing (..)
import FunctionExtra exposing (..)
import ViewState exposing (ViewState)

type EditMode
    = EditNewTodoMode String
    | EditTodoMode Todo
    | NotEditing


type alias Model =
    { now : Time
    , todoList : TodoList
    , editMode : EditMode
    , viewState : ViewState
    , seed : Seed
    }


type alias ModelF =
    Model -> Model

