module Main.View exposing (appView)

import ActiveTask exposing (MaybeActiveTask)
import Html.Attributes.Extra exposing (..)
import Html.Keyed as Keyed
import Html exposing (Attribute, Html, div, hr, node, span, text)
import Html.Attributes exposing (attribute, autofocus, class, classList, id, style, value)
import Html.Events exposing (..)
import KeyboardExtra as KeyboardExtra exposing (onEscape, onKeyUp)
import Main.Types exposing (EditMode(..), MainViewType(..))
import Main.View.AllTodoLists exposing (..)
import Main.View.AppDrawer exposing (appDrawerView)
import Maybe.Extra as Maybe
import Polymer.Attributes exposing (icon)
import Time exposing (Time)
import TimeExtra
import TodoListUpdate
import Toolkit.Helpers exposing (..)
import Toolkit.Operators exposing (..)
import DebugExtra.Debug exposing (tapLog)
import DecodeExtra exposing (traceDecoder)
import Flow
import Json.Decode
import Json.Encode
import List.Extra as List
import Main.Model exposing (..)
import Msg exposing (..)
import Todo exposing (Todo, TodoId)
import Flow.Model as Flow exposing (Node)
import Polymer.Paper exposing (..)
import Polymer.App as App
import FunctionExtra exposing (..)
import FunctionExtra.Operators exposing (..)
import Todo.View


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
        , activeTaskAppToolBarView m
        ]


activeTaskAppToolBarView : Model -> Html Msg
activeTaskAppToolBarView m =
    case getActiveTaskViewModel m of
        Just taskVm ->
            div [ class "active-task-view", attribute "sticky" "true" ] [ activeTaskView taskVm m ]

        Nothing ->
            div [ class "active-task-view", attribute "sticky" "true" ] []


activeTaskView : ActiveTaskViewModel -> Model -> Html Msg
activeTaskView { todoVM, elapsedTime } m =
    div []
        [ div [ class "title" ] [ text todoVM.text ]
        , div [ class "col" ]
            [ div [ class "elapsed-time" ] [ text (TimeExtra.toHHMMSS elapsedTime) ]
            , iconButton [ icon "av:pause" ] []
            , iconButton [ icon "av:stop", Msg.stop |> onClick ] []
            , iconButton [ icon "check", Msg.stopAndMarkDone |> onClick ] []
            ]
        ]


appMainView m =
    div [ id "main-view" ]
        [ case getMainViewType m of
            AllByGroupView ->
                allTodoListByGroupView m

            BinView ->
                todoListView m

            DoneView ->
                todoListView m

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
                , class "auto-focus"
                , onInput onNewTodo.input
                , value text
                , onBlur onNewTodo.blur
                , onKeyUp (onNewTodo.keyUp text)
                ]
                []

        _ ->
            span [] []


addTodoFabView m =
    fab
        [ id "add-fab"
        , attribute "icon" "add"
        , onClick onNewTodo.addClicked
        ]
        []


type alias TodoViewModel =
    Todo
