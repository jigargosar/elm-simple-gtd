module Todos.View exposing (..)

import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Html.Events.Extra exposing (onClickStopPropagation)
import Todos
import Todos.Todo as Todo


listView todosModel =
    ul [] (Todos.map todoView todosModel)


todoView todo =
    li [] [ Todo.getText todo |> text ]
