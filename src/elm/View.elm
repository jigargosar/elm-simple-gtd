module View exposing (init)

import EditMode
import Firebase.View
import Html.Attributes.Extra exposing (..)
import Html exposing (Attribute, Html, a, div, form, h1, h2, h3, h4, h5, h6, hr, input, node, p, span, text)
import Html.Attributes exposing (action, attribute, autofocus, class, classList, id, method, required, style, tabindex, type_, value)
import Html.Events exposing (..)
import Html.Events.Extra exposing (onClickStopPropagation)
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

                EditMode.EditTodoReminder form ->
                    Todo.View.reminderPopup form model

                EditMode.FirstVisit ->
                    firstVisitModal

                _ ->
                    span [] []
    in
        [ Just editModeOverlayView
        , View.ReminderOverlay.maybe model
        ]
            |> List.filterMap identity


firstVisitModal =
    div
        [ class "fullbleed-capture dark"
        , onClickStopPropagation Model.noop
        ]
        [ div [ id "welcome", class "modal open modal-center" ]
            [ div [ class "modal-content" ]
                [ h4 [] [ text "Welcome to SimpleGTD.com" ]
                , div [ class "divider" ] []
                , div [ class "row section" ]
                    [ div [ class "col s12 m6" ] [ span [ class "flow-text" ] [ text "Have an Account?" ] ]
                    , div [ class "col s12 m6" ] [ a [ class "btn" ] [ text "Signin with Google" ] ]
                    ]
                , div [ class "divider" ] []
                , div [ class "row section" ]
                    [ div [ class "col s12 m6" ] [ span [ class "flow-text" ] [ text "Or lets" ] ]
                    , div [ class "col s12 m6" ] [ a [ class "btn" ] [ text "Start Exploring" ] ]
                    ]
                ]
            ]
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
