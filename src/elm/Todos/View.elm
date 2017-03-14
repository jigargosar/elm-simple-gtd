module Todos.View exposing (..)

import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Html.Events.Extra exposing (onClickStopPropagation)
import Todos exposing (TodosModel)
import Todos.Todo as Todo exposing (TodoId)


type alias ViewConfig msg =
    { onAdd : msg
    , onDelete : TodoId -> msg
    , onEdit : TodoId -> msg
    }


listView : ViewConfig msg -> TodosModel -> Html msg
listView viewConfig todosModel =
    div []
        [ innerListView viewConfig todosModel
        , addTodoView viewConfig
        ]


addTodoView viewConfig =
    button [ onClick viewConfig.onAdd ] [ text "Add Todo" ]


innerListView viewConfig todosModel =
    ul [] (Todos.map todoView todosModel)


todoView todo =
    li [] [ Todo.getText todo |> text ]
