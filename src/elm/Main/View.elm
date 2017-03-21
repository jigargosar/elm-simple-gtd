module Main.View exposing (appView)

import Html.Attributes.Extra exposing (intProperty)
import KeyboardExtra as KeyboardExtra exposing (onEscape, onKeyUp)
import Polymer.Attributes exposing (stringProperty)
import Toolkit.Helpers exposing (..)
import Toolkit.Operators exposing (..)
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import DebugExtra.Debug exposing (tapLog)
import DecodeExtra exposing (traceDecoder)
import Flow
import Json.Decode
import Json.Encode
import List.Extra as List
import Main.Model exposing (..)
import Main.Msg exposing (..)
import Todo as Todo exposing (EditMode(..), ListType)
import TodoStore.View
import Flow.Model as Flow exposing (Node)
import InBasketFlow
import InBasketFlow.View
import Polymer.Paper as Paper exposing (drawerPanel, material)


todoListViewConfig =
    { onDeleteTodoClicked = OnDeleteTodoClicked
    , onEditTodoClicked = OnEditTodoClicked
    , onEditTodoTextChanged = OnEditTodoTextChanged
    , onEditTodoBlur = OnEditTodoBlur
    , onEditTodoKeyUp = OnEditTodoKeyUp
    , noOp = NoOp
    , onTodoMoveToClicked = OnTodoMoveToClicked
    }


appView m =
    div []
        [ headerView m
        , appDrawerView m
          --        , div [ id "center-view" ] [ centerView m ]
        , node "paper-fab"
            [ id "add-fab"
            , attribute "icon" "add"
            , onClick (OnAddTodoClicked newTodoInputId)
            ]
            []
        ]


appDrawerView m =
    drawerPanel
        []
        [ div [ attribute "drawer" "true" ]
            [ menu
                [ stringProperty "selected" "0"
                ]
                [ Paper.item [] [ text "Item One" ]
                , Paper.item [] [ text "Item 2" ]
                , Paper.item [] [ text "Item 3" ]
                ]
            ]
        , div
            [ id "center-view"
            , attribute "main" "true"
            ]
            [ centerView m ]
        ]



--appDrawerView m =
--    node "app-drawer"
--        [ stringProperty "persistent" "true"
--        , stringProperty "opened" "true"
--        , stringProperty "elevation" "0"
--        ]
--        [ menu
--            [ stringProperty "selected" "0"
--            ]
--            [ Paper.item [] [ text "Item One" ]
--            , Paper.item [] [ text "Item 2" ]
--            , Paper.item [] [ text "Item 3" ]
--            ]
--        ]


headerView m =
    node "app-header"
        [ attribute "reveals" "true"
        , attribute "fixed" "true"
        , attribute "condenses" "true"
        , attribute "effects" "waterfall"
        ]
        [ node "app-toolbar"
            []
            [ node "paper-icon-button" [ attribute "icon" "menu" ] []
            , node "paper-tabs"
                [ intProperty "selected" (getSelectedTabIndex m) ]
                [ node "paper-tab" [ onClick OnShowTodoList ] [ text "Lists" ]
                , node "paper-tab" [ onClick OnProcessInBasket ] [ text "Process In-Basket" ]
                ]
            , addTodoView (getEditMode m) todoListViewConfig
            ]
        ]


addTodoView editMode viewConfig =
    case editMode of
        EditNewTodoMode text ->
            addNewTodoView viewConfig text

        _ ->
            span [] []


newTodoInputId =
    "new-todo-input"


addNewTodoView vc text =
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

        InBasketFlowViewState maybeTodo inBasketFlowModel ->
            InBasketFlow.View.view maybeTodo inBasketFlowModel


todoListView m =
    TodoStore.View.allTodosView todoListViewConfig (getEditMode m) (getTodoCollection m)
