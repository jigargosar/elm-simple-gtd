module Main.View exposing (appView)

import Html.Attributes.Extra exposing (..)
import KeyboardExtra as KeyboardExtra exposing (onEscape, onKeyUp)
import Polymer.Attributes exposing (icon)
import Toolkit.Helpers exposing (..)
import Toolkit.Operators exposing (..)
import Html exposing (div, hr, node, span, text)
import Html.Attributes exposing (attribute, autofocus, class, classList, id, style, value)
import Html.Events exposing (..)
import DebugExtra.Debug exposing (tapLog)
import DecodeExtra exposing (traceDecoder)
import Flow
import Json.Decode
import Json.Encode
import List.Extra as List
import Main.Model exposing (..)
import Main.Msg exposing (..)
import Todo as Todo exposing (EditMode(..), Group(Inbox))
import TodoStore.View
import Flow.Model as Flow exposing (Node)
import InboxFlow
import InboxFlow.View
import Polymer.Paper as Paper exposing (badge, button, fab, iconButton, item, itemBody, material, menu, tab, tabs)
import Polymer.App exposing (..)
import FunctionExtra exposing (..)
import Main.View.DrawerMenu exposing (appDrawerMenuView)


createTodoListViewConfig : Model -> TodoStore.View.ViewConfig Msg
createTodoListViewConfig model =
    { onDeleteTodoClicked = OnDeleteTodoClicked
    , onEditTodoClicked = OnEditTodoClicked
    , onEditTodoTextChanged = OnEditTodoTextChanged
    , onEditTodoBlur = OnEditTodoBlur
    , onEditTodoKeyUp = OnEditTodoKeyUp
    , noOp = NoOp
    , onTodoMoveToClicked = OnTodoMoveToClicked
    , now = getNow model
    , editMode = getEditMode model
    , onTodoDoneClicked = OnTodoDoneClicked
    }


appView m =
    div []
        [ drawerLayoutView m
        , fab
            [ id "add-fab"
            , attribute "icon" "add"
            , onClick (OnAddTodoClicked newTodoInputId)
            ]
            []
        ]


drawerLayoutView m =
    drawerLayout []
        [ drawer [ attribute "slot" "drawer" ]
            [ toolbar [] [ text "Simple GTD" ]
            , div [ style [ "height" => "100vh", "overflow" => "auto" ] ]
                [ appDrawerMenuView m
                ]
            ]
        , headerLayout []
            [ header
                [ attribute "reveals" "true"
                , attribute "fixed" "true"
                , attribute "condenses" "true"
                , attribute "effects" "waterfall"
                , attribute "slot" "header"
                ]
                [ toolbar
                    []
                    [ iconButton [ icon "menu", attribute "drawer-toggle" "true" ] []
                    , addTodoView (getEditMode m)
                    ]
                ]
            , div [ id "center-view" ] [ centerView m ]
            ]
        ]




addTodoView editMode =
    case editMode of
        EditNewTodoMode text ->
            addNewTodoView text

        _ ->
            span [] []


newTodoInputId =
    "new-todo-input"


addNewTodoView text =
    Paper.input
        [ id newTodoInputId
        , onInput OnNewTodoTextChanged
        , value text
        , onBlur OnNewTodoBlur
        , onKeyUp OnNewTodoKeyUp
        , autofocus True
        ]
        []



--addTodoButton viewConfig =
--    node "paper-fab" [ id "add-fab", attribute "icon" "add", onClick viewConfig.onAddTodoClicked ] []


centerView m =
    case getViewState m of
        TodoListViewState ->
            todoListView m

        InboxFlowViewState maybeTodo inboxFlowModel ->
            InboxFlow.View.view maybeTodo inboxFlowModel


todoListView m =
    --TodoStore.View.allTodosView (createTodoListViewConfig m) (getTodoCollection m)
    div [] []
