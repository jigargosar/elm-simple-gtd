module Todo.View exposing (..)

import Json.Decode
import Polymer.Attributes exposing (boolProperty)
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
        editing =
            case editMode of
                EditTodoMode editingTodo ->
                    Todo.equalById editingTodo todo

                _ ->
                    False

        inner =
            --            case editMode of
            --                EditTodoMode editingTodo ->
            --                    if Todo.equalById editingTodo todo then
            --                        todoListEditView viewConfig editingTodo
            --                    else
            --                        todoListItemView editing viewConfig todo
            --
            --                _ ->
            todoListItemView editing viewConfig todo
    in
        ( Todo.getId todo, inner )


onTap msg =
    on "click" (Json.Decode.succeed msg)


todoListItemView editing viewConfig todo =
    let
        deleteOnClick =
            onTap (viewConfig.onDeleteTodoClicked (Todo.getId todo))

        editOnClick =
            onClick (viewConfig.onEditTodoClicked todo)

        itemBody =
            if editing then
                node "paper-item-body"
                    []
                    [ node "paper-input"
                        [ class "edit-todo-input"
                        , boolProperty "noLabelFloat" True
                        , onInput viewConfig.onEditTodoTextChanged
                        , value (Todo.getText todo)
                        , onBlur viewConfig.onEditTodoBlur
                        , KeyboardExtra.onEscape viewConfig.onNewTodoBlur
                        , KeyboardExtra.onEnter viewConfig.onEditTodoEnterPressed
                        , autofocus True
                        ]
                        []
                    ]
            else
                node "paper-item-body" [ editOnClick ] [ Todo.getText todo |> text ]
    in
        node "paper-item"
            [ class "list-item" ]
            [ checkbox [ checked False ] []
            , itemBody
            , div [ class "hover" ] [ node "paper-icon-button" [ deleteOnClick, attribute "icon" "delete" ] [] ]
            ]
