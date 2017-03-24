module Main.View exposing (appView)

import Html.Attributes.Extra exposing (..)
import Html.Keyed as Keyed
import Html exposing (Attribute, Html, div, hr, node, span, text)
import Html.Attributes exposing (attribute, autofocus, class, classList, id, style, value)
import Html.Events exposing (..)
import KeyboardExtra as KeyboardExtra exposing (onEscape, onKeyUp)
import Main.View.AllTodoLists exposing (allTodoListByGroupView, binView, doneView)
import Main.View.AppDrawer exposing (appDrawerView)
import Maybe.Extra as Maybe
import Polymer.Attributes exposing (icon)
import Toolkit.Helpers exposing (..)
import Toolkit.Operators exposing (..)
import DebugExtra.Debug exposing (tapLog)
import DecodeExtra exposing (traceDecoder)
import Flow
import Json.Decode
import Json.Encode
import List.Extra as List
import Main.Model exposing (..)
import Main.Msg exposing (..)
import Todo exposing (Todo, TodoId)
import Flow.Model as Flow exposing (Node)
import Polymer.Paper exposing (..)
import Polymer.App as App
import FunctionExtra exposing (..)
import Todo.View
import ViewState exposing (..)


appView m =
    div []
        [ appDrawerLayoutView m
        , addTodoFabView m
        ]


appDrawerLayoutView m =
    App.drawerLayout []
        [ appDrawerView m
        , App.headerLayout []
            [ appHeaderView m
            , appMainView m
            ]
        ]


appHeaderView m =
    App.header
        [ attribute "reveals" "true"
        , attribute "fixed" "true"
        , attribute "condenses" "true"
        , attribute "effects" "waterfall"
        , attribute "slot" "header"
        ]
        [ App.toolbar
            []
            [ iconButton [ icon "menu", attribute "drawer-toggle" "true" ] []
            , newTodoInputView (getEditMode m)
            ]
        ]


appMainView m =
    div [ id "main-view" ]
        [ case getViewState m of
            ViewState.AllGrouped ->
                allTodoListByGroupView m

            ViewState.Bin ->
                binView m

            ViewState.Done ->
                doneView m

            _ ->
                allTodoListByGroupView m
        ]


newTodoInputId =
    "new-todo-input"


newTodoInputView editMode =
    case editMode of
        EditNewTodoMode text ->
            input
                [ id newTodoInputId
                , onInput OnNewTodoTextChanged
                , value text
                , onBlur OnNewTodoBlur
                , onKeyUp (OnNewTodoKeyUp text)
                , autofocus True
                ]
                []

        _ ->
            span [] []


addTodoFabView m =
    fab
        [ id "add-fab"
        , attribute "icon" "add"
        , onClick (OnAddTodoClicked newTodoInputId)
        ]
        []
