module View exposing (init)

import EditMode
import Firebase.View
import Html.Attributes.Extra exposing (..)
import Html exposing (Attribute, Html, div, form, h1, h2, hr, input, node, span, text)
import Html.Attributes exposing (action, attribute, autofocus, class, classList, id, method, required, style, tabindex, type_, value)
import Html.Events exposing (..)
import Model
import Model exposing (Msg, commonMsg)
import View.Header
import Main.View
import View.AppDrawer
import Model exposing (..)
import Polymer.Paper as Paper exposing (dialog, material)
import Polymer.App as App
import Ext.Function.Infix exposing (..)
import View.ReminderOverlay exposing (maybe)
import Todo.View
import ViewModel
import WebComponents exposing (doneAllIconP, dynamicAlign, icon, iconA, iconButton, iconTextButton, onBoolPropertyChanged, onPropertyChanged, paperIconButton, slotDropdownContent, slotDropdownTrigger, testDialog)
import LaunchBar.View


init m =
    div [ id "root" ]
        ([ Firebase.View.init m
         , appView m
         ]
        )


appView model =
    let
        children =
            [ appDrawerLayoutView model
            , addTodoFab model
            ]
                ++ overlayViews model
    in
        div [ id "app-view" ] children


overlayViews model =
    let
        editModeOverlayView =
            case Model.getEditMode model of
                EditMode.LaunchBar form ->
                    LaunchBar.View.init form model

                EditMode.EditTodoContext form ->
                    Todo.View.contextMenu form model

                EditMode.EditTodoProject form ->
                    Todo.View.projectMenu form model

                {- EditMode.EditTodoReminder form ->
                   Todo.View.reminderPopup form model
                -}
                _ ->
                    span [] []
    in
        [ Just editModeOverlayView
        , View.ReminderOverlay.maybe model
        ]
            |> List.filterMap identity


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

        forceNarrow =
            Model.getLayoutForceNarrow m
    in
        App.drawerLayout
            [ boolProperty "forceNarrow" forceNarrow
            , onBoolPropertyChanged "narrow" Model.OnLayoutNarrowChanged
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
        , onClick Model.NewTodo
        , tabindex -1
        ]
        []
