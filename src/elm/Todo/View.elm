module Todo.View exposing (..)

import Json.Decode
import Polymer.Attributes exposing (boolProperty, icon)
import Todo exposing (EditMode(EditTodoMode))
import Toolkit.Helpers exposing (..)
import Toolkit.Operators exposing (..)
import FunctionExtra exposing (..)
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import KeyboardExtra exposing (onEscape)
import Polymer.Paper as Paper exposing (checkbox, iconButton, item, itemBody)


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
            todoItemView editing viewConfig todo
    in
        ( Todo.getId todo, inner )


todoItemBody editing vc todo =
    let
        onEditTodoClicked =
            onClick (vc.onEditTodoClicked todo)
    in
        if editing then
            itemBody []
                [ Paper.input
                    [ class "edit-todo-input"
                    , boolProperty "noLabelFloat" True
                    , value (Todo.getText todo)
                    , onInput vc.onEditTodoTextChanged
                    , onBlur vc.onEditTodoBlur
                    , KeyboardExtra.onEscape vc.onNewTodoBlur
                    , KeyboardExtra.onEnter vc.onEditTodoEnterPressed
                    , autofocus True
                    ]
                    []
                ]
        else
            itemBody [ onEditTodoClicked ] [ Todo.getText todo |> text ]


todoItemView editing vc todo =
    let
        deleteOnClick =
            onClick (vc.onDeleteTodoClicked (Todo.getId todo))
    in
        item []
            [ checkbox [ checked False ] []
            , todoItemBody editing vc todo
            , div [ class "hover" ] [ iconButton [ deleteOnClick, icon "delete" ] [] ]
            ]
