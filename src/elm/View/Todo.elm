module View.Todo exposing (..)

import Date.Distance exposing (inWords)
import Html.Events.Extra exposing (onClickStopPropagation)
import Json.Decode
import Keyboard.Extra exposing (Key(Enter, Escape))
import Polymer.Attributes exposing (boolProperty, icon, stringProperty)
import Todo
import Toolkit.Helpers exposing (..)
import Toolkit.Operators exposing (..)
import FunctionExtra exposing (..)
import FunctionExtra.Operators exposing (..)
import Html exposing (div, span, text)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import KeyboardExtra exposing (onEscape, onKeyUp)
import Polymer.Paper exposing (..)


todoViewEditing vc todo =
    item [ class "todo-item" ]
        [ itemBody []
            [ input
                [ id (todoInputId todo)
                , class "edit-todo-input auto-focus"
                , boolProperty "noLabelFloat" True
                , value (Todo.getText todo)
                , onInput vc.onEditTodoTextChanged
                , onBlur (vc.onEditTodoBlur todo)
                , onKeyUp (vc.onEditTodoKeyUp todo)
                , autofocus True
                , placeholder "Todo Text"
                ]
                []
            ]
        ]


todoViewNotEditing vc todo =
    item
        [ class "todo-item"
        , onClickStopPropagation (vc.onEditTodoClicked todo)
        ]
        [ checkBoxView
        , itemBody []
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
        , hoverIcons vc todo
        , nonHoverIcons vc todo
        ]


checkBoxView =
    checkbox [ checked False ] []


todoInputId todo =
    "edit-todo-input-" ++ (Todo.getId todo)


hoverIcons vc todo =
    div [ class "show-on-hover" ]
        [ --        startIconButton vc todo
          doneIconButton vc todo
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
    iconButton [ onClickStopPropagation (vc.onDeleteTodoClicked (Todo.getId todo)), icon "delete" ] []


startIconButton vc todo =
    iconButton [ onClickStopPropagation (vc.onTodoStartClicked (Todo.getId todo)), icon "av:play-circle-outline" ] []


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
            (Todo.getAllTodoGroups
                .|> (\listType ->
                        item
                            [ attribute "list-type" (Todo.groupToName listType)
                            , onClickStopPropagation (vc.onTodoMoveToClicked listType (Todo.getId todo))
                            ]
                            [ text (Todo.groupToName listType) ]
                    )
            )
        ]
