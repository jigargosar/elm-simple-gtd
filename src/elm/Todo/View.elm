module Todo.View exposing (..)

import Date.Distance exposing (inWords)
import Html.Events.Extra exposing (onClickStopPropagation)
import Json.Decode
import Keyboard.Extra exposing (Key(Enter, Escape))
import Main.Msg
import Polymer.Attributes exposing (boolProperty, icon, stringProperty)
import Todo
import Toolkit.Helpers exposing (..)
import Toolkit.Operators exposing (..)
import FunctionExtra exposing (..)
import Html exposing (div, span, text)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import KeyboardExtra exposing (onEscape, onKeyUp)
import Polymer.Paper exposing (..)


todoViewEditing vc todo =
    let
        itemBodyView =
            itemBody []
                [ input
                    [ id (todoInputId todo)
                    , class "edit-todo-input"
                    , boolProperty "noLabelFloat" True
                    , value (Todo.getText todo)
                    , onInput vc.onEditTodoTextChanged
                    , onBlur (vc.onEditTodoBlur todo)
                    , onKeyUp (vc.onEditTodoKeyUp todo)
                    , autofocus True
                    ]
                    []
                ]
    in
        todoViewWithItemBodyView itemBodyView vc todo


todoViewNotEditing vc todo =
    let
        itemBodyView =
            itemBody []
                [ span
                    [ classList
                        [ "ellipsis" => True
                        , "done" => Todo.isDone todo
                        ]
                    ]
                    [ Todo.getText todo |> text ]
                , span [ class "small dim" ]
                    [ text ("created " ++ (Todo.createdAtInWords vc.now todo) ++ " ago. ")
                    , text ("modified " ++ (Todo.modifiedAtInWords vc.now todo) ++ " ago")
                    ]
                ]
    in
        todoViewWithItemBodyView itemBodyView vc todo


todoViewWithItemBodyView itemBodyView vc todo =
    item (todoItemAttributes vc todo)
        [ checkBoxView
        , itemBodyView
        , hoverIcons vc todo
        , nonHoverIcons vc todo
        ]


checkBoxView =
    checkbox [ checked False ] []


todoItemAttributes vc todo =
    [ class "todo-item"
    , onClick (vc.onEditTodoClicked (todoInputId todo) todo)
    ]


todoInputId todo =
    "edit-todo-input-" ++ (Todo.getId todo)


hoverIcons vc todo =
    div [ class "show-on-hover" ]
        [ doneIconButton vc todo
        , deleteIconButton vc todo
        , optionsIconButton vc todo
        ]


nonHoverIcons vc todo =
    div [ class "hide-on-hover" ]
        ([] ++ (ifElse Todo.isDone (doneIconButton vc >> List.singleton) (\_ -> []) todo))


doneIconButton vc todo =
    iconButton
        [ class ("done-" ++ toString (Todo.isDone todo))
        , onClickStopPropagation (vc.onTodoDoneClicked (Todo.getId todo))
        , icon "check"
        ]
        []


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
            (Todo.getTodoGroups
                .|> (\listType ->
                        item
                            [ attribute "list-type" (Todo.todoGroupToName listType)
                            , onClick (vc.onTodoMoveToClicked listType todo)
                            ]
                            [ text (Todo.todoGroupToName listType) ]
                    )
            )
        ]
