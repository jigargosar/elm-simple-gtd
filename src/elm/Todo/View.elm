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


todoView viewConfig (( editing, todo ) as editingTodoTuple) =
    todoItemView viewConfig editingTodoTuple


todoViewEditing vc todo =
    item [ class "todo-item" ]
        [ checkbox [ checked False ] []
        , itemBody []
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
        , hoverIcons vc todo
        ]


todoViewNotEditing vc todo =
    item
        [ class "todo-item"
        , onClick (vc.onEditTodoClicked (todoInputId todo) todo)
        ]
        [ checkbox [ checked False ] []
        , itemBody []
            [ span [ class "ellipsis" ] [ Todo.getText todo |> text ]
            , span [ class "small dim" ]
                [ text ("created " ++ (Todo.createdAtInWords vc.now todo) ++ " ago. ")
                , text ("modified " ++ (Todo.modifiedAtInWords vc.now todo) ++ " ago")
                ]
            ]
        , hoverIcons vc todo
        ]


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
            , span [ class "small dim" ]
                [ text ("created " ++ (Todo.createdAtInWords vc.now todo) ++ " ago. ")
                , text ("modified " ++ (Todo.modifiedAtInWords vc.now todo) ++ " ago")
                ]
            ]


hoverIcons vc todo =
    div [ class "hover hover-icons" ]
        [ doneIconButton vc todo
        , deleteIconButton vc todo
        , optionsIconButton vc todo
        ]


todoItemView vc ( editing, todo ) =
    let
        itemOptionalAttributes =
            if editing then
                []
            else
                [ onClick (vc.onEditTodoClicked (todoInputId todo) todo) ]

        itemAttributes =
            [ class "todo-item" ] ++ itemOptionalAttributes
    in
        todoItemViewHelp itemAttributes editing vc todo


todoItemViewHelp itemAttributes editing vc todo =
    item itemAttributes
        [ checkbox [ checked False ] []
        , todoItemBody editing vc todo
        , hoverIcons vc todo
        ]


doneIconButton vc todo =
    iconButton
        [ class "check"
        , onClick (vc.onTodoDoneClicked (Todo.getId todo))
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
