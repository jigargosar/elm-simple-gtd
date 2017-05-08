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
import Msg exposing (Msg)
import Polymer.Firebase
import ReminderOverlay
import Set
import Entity.ViewModel
import View.Header
import Main.View
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
    in
        App.drawerLayout
            [ boolProperty "forceNarrow" m.appDrawerForceNarrow
            ]
            [ View.AppDrawer.view viewModel m
            , App.headerLayout [ attribute "has-scrolling-region" "" ]
                [ View.Header.init viewModel m
                , Main.View.init viewModel m
                ]
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
