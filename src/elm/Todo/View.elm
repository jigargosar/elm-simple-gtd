module Todo.View exposing (..)

import Json.Decode
import Todo exposing (EditMode(EditTodoMode))
import Toolkit.Helpers exposing (..)
import Toolkit.Operators exposing (..)
import FunctionExtra exposing (..)
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import KeyboardExtra exposing (onEscape)
import Polymer.Paper as Paper exposing (checkbox)


todoView editMode viewConfig todo =
    let
        inner =
            case editMode of
                EditTodoMode editingTodo ->
                    if Todo.equalById editingTodo todo then
                        todoListEditView viewConfig editingTodo
                    else
                        todoListItemView viewConfig todo

                _ ->
                    todoListItemView viewConfig todo
    in
        ( Todo.getId todo, inner )


onTap msg =
    on "click" (Json.Decode.succeed msg)


todoListItemView viewConfig todo =
    let
        deleteOnClick =
            onTap (viewConfig.onDeleteTodoClicked (Todo.getId todo))

        editOnClick =
            onClick (viewConfig.onEditTodoClicked todo)
    in
        node "paper-item"
            [ class "list-item" ]
            [ checkbox [ checked False ] []
            , node "paper-item-body" [ editOnClick ] [ Todo.getText todo |> text ]
            , div [ class "hover" ] [ node "paper-icon-button" [ deleteOnClick, attribute "icon" "delete" ] [] ]
            ]


todoListEditView viewConfig todo =
    node "paper-item"
        [ class "list-item" ]
        [ node "paper-input"
            [ class "edit-todo-input"
            , onInput viewConfig.onEditTodoTextChanged
            , value (Todo.getText todo)
            , onBlur viewConfig.onEditTodoBlur
            , KeyboardExtra.onEscape viewConfig.onNewTodoBlur
            , KeyboardExtra.onEnter viewConfig.onEditTodoEnterPressed
            , autofocus True
            ]
            []
        ]
