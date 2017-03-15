module Todos.View exposing (..)

import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Html.Events.Extra exposing (onClickStopPropagation, onEnter)
import Todos exposing (EditMode(..), TodosModel)
import Todos.Todo as Todo exposing (TodoId)


type alias ViewConfig msg =
    { onAddTodoClicked : msg
    , onDelete : TodoId -> msg
    , onEdit : TodoId -> msg
    , onNewTodoTextChanged : String -> msg
    , onNewTodoBlur : msg
    , onNewTodoEnterPressed : msg
    }


allTodosView : ViewConfig msg -> EditMode -> TodosModel -> Html msg
allTodosView viewConfig editMode todosModel =
    div []
        [ todoListView viewConfig todosModel
        , addTodoView viewConfig editMode
        ]


addTodoView viewConfig editMode =
    case editMode of
        EditNewTodoMode text ->
            addNewTodoView viewConfig text

        _ ->
            addTodoButton viewConfig


addTodoButton viewConfig =
    button
        [ onClick viewConfig.onAddTodoClicked
        ]
        [ text "Add Todo" ]


addNewTodoView viewConfig text =
    input
        [ onInput viewConfig.onNewTodoTextChanged
        , value text
        , onBlur viewConfig.onNewTodoBlur
        , autofocus True
        , onEnter viewConfig.onNewTodoEnterPressed
        ]
        []


todoListView viewConfig todosModel =
    ul [] (Todos.map (todoView viewConfig.onDelete viewConfig.onEdit) todosModel)


todoView onDelete onEdit todo =
    let
        deleteOnClick =
            onClick (onDelete (Todo.getId todo))

        editOnClick =
            onClick (onEdit (Todo.getId todo))
    in
        div []
            [ button [ deleteOnClick ] [ text "x" ]
            , div [ editOnClick ] [ Todo.getText todo |> text ]
            ]
