module Todo.View exposing (..)

import Date.Distance exposing (inWords)
import Html.Events.Extra exposing (onClickStopPropagation)
import Json.Decode
import Keyboard.Extra exposing (Key(Enter, Escape))
import Main.Msg
import Polymer.Attributes exposing (boolProperty, icon, stringProperty)
import Todo exposing (EditMode(EditTodoMode))
import Toolkit.Helpers exposing (..)
import Toolkit.Operators exposing (..)
import FunctionExtra exposing (..)
import Html exposing (div, span, text)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import KeyboardExtra exposing (onEscape, onKeyUp)
import Polymer.Paper exposing (..)


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


todoInputId todo =
    "edit-todo-input-" ++ (Todo.getId todo)


todoItemBody editing vc todo =
    if editing then
        itemBody []
            [ input
                [ id (todoInputId todo)
                , class "edit-todo-input"
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
        itemBody []
            [ span [ class "ellipsis" ] [ Todo.getText todo |> text ]
            , span [] [ text ("created " ++ (Todo.createdAtInWords vc.now todo) ++ "ago") ]
            ]


todoItemView vc ( editing, todo ) =
    let
        hoverIcons =
            div [ class "hover hover-icons" ]
                [ doneIconButton vc todo
                , deleteIconButton vc todo
                , optionsIconButton vc todo
                ]

        onEditTodoClicked =
            onClick (vc.onEditTodoClicked (todoInputId todo) todo)

        itemOptionalAttributes =
            if editing then
                []
            else
                [ onEditTodoClicked ]

        itemAttributes =
            [ class "todo-item" ] ++ itemOptionalAttributes
    in
        item itemAttributes
            [ checkbox [ checked False ] []
            , todoItemBody editing vc todo
            , hoverIcons
            ]


doneIconButton vc todo =
    iconButton [ class "check", icon "check" ] []


deleteIconButton vc todo =
    iconButton [ onClick (vc.onDeleteTodoClicked (Todo.getId todo)), icon "delete" ] []


optionsIconButton vc todo =
    menuButton
        [ onClickStopPropagation vc.noOp
        , attribute "horizontal-align" "right"
        ]
        [ iconButton [ icon "more-vert", class "dropdown-trigger" ] []
        , menu
            [ class "dropdown-content"
            , attribute "attr-for-selected" "list-type"
            , attribute "selected" (Todo.getListTypeName todo)
            ]
            (Todo.getAllListTypes
                .|> (\listType ->
                        item
                            [ attribute "list-type" (Todo.listTypeToName listType)
                            , onClick (vc.onTodoMoveToClicked listType todo)
                            ]
                            [ text (Todo.listTypeToName listType) ]
                    )
            )
        ]
