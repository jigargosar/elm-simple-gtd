module Todo.View exposing (..)

import Json.Decode
import Keyboard.Extra exposing (Key(Enter, Escape))
import Polymer.Attributes exposing (boolProperty, icon)
import Todo exposing (EditMode(EditTodoMode))
import Toolkit.Helpers exposing (..)
import Toolkit.Operators exposing (..)
import FunctionExtra exposing (..)
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import KeyboardExtra exposing (onEscape, onKeyUp)
import Polymer.Paper as Paper exposing (checkbox, iconButton, item, itemBody)


todoView editMode viewConfig todo =
    let
        editingTodoTuple =
            case editMode of
                EditTodoMode editingTodo ->
                    if Todo.equalById editingTodo todo then
                        ( True, editingTodo )
                    else
                        ( False, todo )

                _ ->
                    ( False, todo )

        inner =
            --            case editMode of
            --                EditTodoMode editingTodo ->
            --                    if Todo.equalById editingTodo todo then
            --                        todoListEditView viewConfig editingTodo
            --                    else
            --                        todoListItemView editing viewConfig todo
            --
            --                _ ->
            todoItemView viewConfig editingTodoTuple
    in
        ( Todo.getId todo, inner )


todoItemBody editing vc todo =
    if editing then
        itemBody []
            [ Paper.input
                [ class "edit-todo-input"
                , boolProperty "noLabelFloat" True
                , value (Todo.getText todo)
                , onInput vc.onEditTodoTextChanged
                , onBlur vc.onEditTodoBlur
                , onKeyUp vc.onEditTodoKeyUp
                , autofocus True
                ]
                []
            ]
    else
        itemBody [] [ Todo.getText todo |> text ]


todoItemView vc ( editing, todo ) =
    let
        hoverIcons =
            div [ class "hover" ]
                [ deleteIconButton vc todo
                ]

        onEditTodoClicked =
            onClick (vc.onEditTodoClicked todo)

        itemOptionalAttributes =
            if editing then
                []
            else
                [ onEditTodoClicked ]

        itemAttributes =
            [] ++ itemOptionalAttributes
    in
        item itemAttributes
            [ checkbox [ checked False ] []
            , todoItemBody editing vc todo
            , hoverIcons
            ]


deleteIconButton vc todo =
    iconButton [ onClick (vc.onDeleteTodoClicked (Todo.getId todo)), icon "delete" ] []
