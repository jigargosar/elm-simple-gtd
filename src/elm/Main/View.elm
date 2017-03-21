module Main.View exposing (appView)

import Html.Attributes.Extra exposing (..)
import KeyboardExtra as KeyboardExtra exposing (onEscape, onKeyUp)
import Polymer.Attributes exposing (icon)
import Toolkit.Helpers exposing (..)
import Toolkit.Operators exposing (..)
import Html exposing (div, span, text)
import Html.Attributes exposing (class, classList, id, attribute, value, autofocus)
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
import Polymer.Paper as Paper exposing (fab, iconButton, item, material, menu, tab, tabs)
import Polymer.App exposing (..)


todoListViewConfig =
    { onDeleteTodoClicked = OnDeleteTodoClicked
    , onEditTodoClicked = OnEditTodoClicked
    , onEditTodoTextChanged = OnEditTodoTextChanged
    , onEditTodoBlur = OnEditTodoBlur
    , onEditTodoKeyUp = OnEditTodoKeyUp
    , noOp = NoOp
    , onTodoMoveToClicked = OnTodoMoveToClicked
    }



--        , appDrawerView m


appView m =
    div []
        [ --        headerLayoutView m
          drawerLayoutView m
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
            [ toolbar []
                [ iconButton [ icon "menu", attribute "drawer-toggle" "true" ] []
                , text "Foo Doo"
                ]
            ]
        , headerLayoutView m
        ]


headerLayoutView m =
    headerLayout []
        [ headerView m
        , mainView m
        ]


headerView m =
    header
        [ attribute "reveals" "true"
        , attribute "fixed" "true"
        , attribute "condenses" "true"
        , attribute "effects" "waterfall"
        , attribute "slot" "header"
        ]
        [ toolbar
            []
            [ iconButton [ icon "menu", attribute "drawer-toggle" "true" ] []
            , tabs
                [ intProperty "selected" (getSelectedTabIndex m) ]
                [ tab [ onClick OnShowTodoList ] [ text "Lists" ]
                , tab [ onClick OnProcessInBasket ] [ text "Process In-Basket" ]
                ]
            , addTodoView (getEditMode m) todoListViewConfig
            ]
        ]


mainView m =
    div [ id "center-view" ] [ centerView m ]



--appDrawerView m =
--    drawerPanel
--        []
--        [ div [ attribute "drawer" "true" ]
--            [ menu
--                [ stringProperty "selected" "0"
--                ]
--                [ Paper.item [] [ text "Item One" ]
--                , Paper.item [] [ text "Item 2" ]
--                , Paper.item [] [ text "Item 3" ]
--                ]
--            ]
--        , div
--            [ id "center-view"
--            , attribute "main" "true"
--            ]
--            [ centerView m ]
--        ]
--


appDrawerView m =
    drawer
        [ stringProperty "persistent" "true"
        , stringProperty "opened" "true"
        , stringProperty "elevation" "0"
        ]
        [ menu
            [ stringProperty "selected" "0"
            ]
            [ item [] [ text "Item One" ]
            , item [] [ text "Item 2" ]
            , item [] [ text "Item 3" ]
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
