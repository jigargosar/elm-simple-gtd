module View exposing (init)

import EditMode
import Firebase
import Firebase.View
import Html.Attributes.Extra exposing (..)
import Html.Keyed as Keyed
import Html exposing (Attribute, Html, div, form, h1, h2, hr, input, node, span, text)
import Html.Attributes exposing (action, attribute, autofocus, class, classList, id, method, required, style, tabindex, type_, value)
import Html.Events exposing (..)
import Ext.Keyboard as Keyboard exposing (onEscape, onKeyUp)
import Model
import Model.Internal as Model
import Model.RunningTodo exposing (RunningTodoViewModel)
import Msg exposing (Msg)
import Polymer.Firebase
import ReminderOverlay
import Set
import Entity.ViewModel
import Test.View
import View.Header
import View.Main
import View.TodoList
import View.AppDrawer
import Maybe.Extra as Maybe
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
import Polymer.Paper as Paper exposing (dialog, material)
import Polymer.App as App
import Ext.Function exposing (..)
import Ext.Function.Infix exposing (..)
import View.ReminderOverlay exposing (showReminderOverlay)
import View.Shared exposing (..)
import Todo.View
import ViewModel
import WebComponents exposing (doneAllIconP, dynamicAlign, icon, iconButton, iconA, iconTextButton, onPropertyChanged, paperIconButton, slotDropdownContent, slotDropdownTrigger, testDialog)


init m =
    div [ id "root" ]
        [ Firebase.View.init m
        , appView m
        ]


appView m =
    div [ id "app-view" ]
        [ appDrawerLayoutView m
        , addTodoFab m
        , showReminderOverlay m
        ]


bottomSheet =
    div [ class "full-view" ]
        [ Paper.material [ style [ "background-color" => "white" ], class "fixed-bottom", attribute "elevation" "5" ]
            [ Paper.item [] [ text "bottom" ]
            , Paper.item [] [ text "bottom" ]
            , Paper.item [] [ text "bottom" ]
            ]
        ]


appDrawerLayoutView m =
    let
        viewModel =
            ViewModel.create m

        { contexts, projects } =
            viewModel

        contextVMs =
            contexts.entityList

        projectVMs =
            projects.entityList
    in
        App.drawerLayout
            [ boolProperty "forceNarrow" m.appDrawerForceNarrow
            ]
            [ View.AppDrawer.view m viewModel
            , App.headerLayout [ attribute "has-scrolling-region" "" ]
                [ View.Header.init m viewModel
                , View.Main.init viewModel contextVMs projectVMs m
                ]
            ]


appMainView contextVMs projectVMs model =
    div [ id "main-view", class "" ]
        [ case Model.getMainViewType model of
            GroupByContextView ->
                View.TodoList.groupByEntity contextVMs model

            GroupByProjectView ->
                View.TodoList.groupByEntity projectVMs model

            ProjectView id ->
                View.TodoList.groupByEntityWithId projectVMs id model

            ContextView id ->
                View.TodoList.groupByEntityWithId contextVMs id model

            BinView ->
                View.TodoList.filtered model

            DoneView ->
                View.TodoList.filtered model

            SyncView ->
                let
                    form =
                        Model.getRemoteSyncForm model
                in
                    Paper.material [ class "static layout vertical" ]
                        [ Paper.input
                            [ attribute "label" "Cloudant URL or any CouchDB URL"
                            , value form.uri
                            , onInput (Msg.UpdateRemoteSyncFormUri form)
                            ]
                            []
                        , div []
                            [ Paper.button [ form |> Msg.RemotePouchSync >> onClick ] [ text "Sync" ]
                            ]
                        ]

            TestView ->
                Test.View.init model.testModel
        ]


addTodoFab m =
    Paper.fab
        [ id "add-fab"
        , attribute "icon" "add"
        , attribute "mini" ""
        , onClick Msg.StartAddingTodo
        , tabindex -1
        ]
        []
