module Todos.View exposing (..)

import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Html.Events.Extra exposing (onClickStopPropagation)
import Todos exposing (EditMode(..), TodosModel)
import Todos.Todo as Todo exposing (TodoId)


type alias ViewConfig msg =
    { onAddTodoClicked : msg
    , onDelete : TodoId -> msg
    , onEdit : TodoId -> msg
    , onNewTodoTextChanged : String -> msg
    , onNewTodoBlur : msg
    }


listView : ViewConfig msg -> EditMode -> TodosModel -> Html msg
listView viewConfig editMode todosModel =
    div []
        [ innerListView viewConfig todosModel
        , addTodoView viewConfig editMode
        ]


addTodoView viewConfig editMode =
    case editMode of
        AddingNewTodo text ->
            addNewTodoView viewConfig text

        _ ->
            addTodoButton viewConfig


addTodoButton viewConfig =
    button [ onClick viewConfig.onAddTodoClicked ] [ text "Add Todo" ]


addNewTodoView viewConfig text =
    input [ onInput viewConfig.onNewTodoTextChanged, value text ] []


innerListView viewConfig todosModel =
    ul [] (Todos.map todoView todosModel)


todoView todo =
    li [] [ Todo.getText todo |> text ]
