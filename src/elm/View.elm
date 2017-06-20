module View exposing (init)

import ActionList
import ActionList.View
import GroupDoc.EditView
import ExclusiveMode
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
import Polymer.Paper as Paper
import Polymer.App as App
import Ext.Function.Infix exposing (..)
import View.ReminderOverlay exposing (maybe)
import Todo.View
import ViewModel
import WebComponents exposing (onBoolPropertyChanged)
import LaunchBar.View
import GroupDoc.EditView


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


overlayViews appModel =
    let
        editModeOverlayView =
            case Model.getEditMode appModel of
                ExclusiveMode.LaunchBar form ->
                    LaunchBar.View.init form appModel

                ExclusiveMode.EditTodoContext form ->
                    Todo.View.contextMenu form appModel

                ExclusiveMode.EditTodoProject form ->
                    Todo.View.projectMenu form appModel

                ExclusiveMode.EditTodoReminder form ->
                    Todo.View.reminderPopup form

                ExclusiveMode.FirstVisit ->
                    firstVisitModal

                ExclusiveMode.ActionList model ->
                    ActionList.View.init appModel model

                ExclusiveMode.EditProject form ->
                    GroupDoc.EditView.init form

                ExclusiveMode.EditContext form ->
                    GroupDoc.EditView.init form

                ExclusiveMode.EditTask form ->
                    Todo.View.edit form appModel

                ExclusiveMode.NewTodo form ->
                    Todo.View.new form

                _ ->
                    span [] []
    in
        [ Just editModeOverlayView
        , View.ReminderOverlay.maybe appModel
        ]
            |> List.filterMap identity


firstVisitModal =
    div
        [ class "overlay"
        , onClickStopPropagation Model.noop
        ]
        [ div [ id "welcome", class "modal fixed-center" ]
            [ div [ class "modal-content" ]
                [ h4 [] [ text "Welcome to SimpleGTD.com" ]
                , div [ class "divider" ] []
                , div [ class "row section" ]
                    [ div [ class "col s12 m6" ]
                        [ span [ class "flow-text" ]
                            [ text "Already have an account with us?" ]
                        ]
                    , div [ class "col s12 m6" ]
                        [ a [ class "btn", onClick Model.OnSignIn ] [ text "Signin" ]
                        ]
                    ]
                , div [ class "divider" ] []
                , div [ class "row section" ]
                    [ div [ class "col s12 m6" ]
                        [ span [ class "flow-text" ]
                            [ text "Or lets" ]
                        ]
                    , div [ class "col s12 m6" ]
                        [ a [ class "btn", onClick Model.OnCreateDefaultEntities ]
                            [ text "Get Started" ]
                        ]
                    ]
                ]
            , div [ class "divider" ] []
            , div [ class "right-align" ]
                [ a [ class "btn btn-flat", onClick Model.OnDeactivateEditingMode ]
                    [ text "Skip creating sample items" ]
                ]
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
