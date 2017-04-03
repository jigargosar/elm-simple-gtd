module View exposing (appView)

import Html.Attributes.Extra exposing (..)
import Html.Keyed as Keyed
import Html exposing (Attribute, Html, div, h1, hr, node, span, text)
import Html.Attributes exposing (attribute, autofocus, class, classList, id, style, value)
import Html.Events exposing (..)
import Ext.Keyboard as Keyboard exposing (onEscape, onKeyUp)
import Model
import Model.EditModel
import Model.RunningTodo exposing (RunningTodoViewModel)
import Msg exposing (..)
import View.TodoList exposing (..)
import View.AppDrawer exposing (appDrawerView)
import Maybe.Extra as Maybe
import Polymer.Attributes exposing (icon)
import Time exposing (Time)
import Ext.Time
import Toolkit.Helpers exposing (..)
import Toolkit.Operators exposing (..)
import Ext.Debug exposing (tapLog)
import Ext.Decode exposing (traceDecoder)
import Json.Decode
import Json.Encode
import List.Extra as List
import Model.Types exposing (..)
import Todo
import Todo.Types exposing (..)
import Polymer.Paper exposing (..)
import Polymer.App as App
import Ext.Function exposing (..)
import Ext.Function.Infix exposing (..)
import View.ProjectList exposing (projectListView)
import View.Todo


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
            , newTodoInputView (Model.EditModel.getEditNewTodoModel m)
            ]
          --        , runningTodoView m
        ]


runningTodoView : Model -> Html Msg
runningTodoView m =
    case Model.RunningTodo.getRunningTodoViewModel m of
        Just taskVm ->
            div [ class "active-task-view", attribute "sticky" "true" ] [ runningTodoViewHelp taskVm m ]

        Nothing ->
            div [ class "active-task-view", attribute "sticky" "true" ] []


runningTodoViewHelp : RunningTodoViewModel -> Model -> Html Msg
runningTodoViewHelp { todoVM, elapsedTime } m =
    div []
        [ div [ class "title" ] [ text todoVM.text ]
        , div [ class "col" ]
            [ div [ class "elapsed-time" ] [ text (Ext.Time.toHHMMSS elapsedTime) ]
            , iconButton [ icon "av:pause" ] []
            , iconButton [ icon "av:stop", Msg.stop |> onClick ] []
            , iconButton [ icon "check", Msg.stopAndMarkDone |> onClick ] []
            ]
        ]


appMainView m =
    div [ id "main-view" ]
        [ case Model.getMainViewType m of
            AllByTodoContextView ->
                allTodoListByTodoContextView m

            BinView ->
                todoListView m

            DoneView ->
                todoListView m

            ProjectsView ->
                projectListView m

            TodoContextView _ ->
                allTodoListByTodoContextView m
        ]


newTodoInputId =
    "new-todo-input"


newTodoInputView maybeNewTodoModel =
    case maybeNewTodoModel of
        Just text ->
            input
                [ id newTodoInputId
                , class "auto-focus"
                , onInput onNewTodoInput
                , value text
                , onBlur onNewTodoBlur
                , onKeyUp (onNewTodoKeyUp text)
                , stringProperty "label" "New Todo"
                , boolProperty "alwaysFloatLabel" True
                , style [ ( "width", "100%" ), "color" => "white" ]
                ]
                []

        Nothing ->
            h1 [ id "toolbar-title" ] [ text "SimpleGTD" ]


addTodoFabView m =
    fab
        [ id "add-fab"
        , attribute "icon" "add"
        , onClick startAddingTodo
        ]
        []


type alias TodoViewModel =
    Todo
