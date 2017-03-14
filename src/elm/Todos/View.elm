module Todos.View exposing (..)

import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Html.Events.Extra exposing (onClickStopPropagation)
import Todos exposing (EditMode, TodosModel)
import Todos.Todo as Todo exposing (TodoId)


type alias ViewConfig msg =
    { onAddTodoClicked : msg
    , onDelete : TodoId -> msg
    , onEdit : TodoId -> msg
    }


listView : ViewConfig msg -> EditMode -> TodosModel -> Html msg
listView viewConfig editMode todosModel =
    div []
        [ innerListView viewConfig todosModel
        , addTodoView viewConfig
        ]


addTodoView viewConfig =
    button [ onClick viewConfig.onAddTodoClicked ] [ text "Add Todo" ]


innerListView viewConfig todosModel =
    ul [] (Todos.map todoView todosModel)


todoView todo =
    li [] [ Todo.getText todo |> text ]
