module View exposing (init)

import ActionList
import ActionList.View
import AppUrl
import CustomSync
import EntityList.View
import Svg
import X.Html exposing (boolProperty, onClickStopPropagation)
import GroupDoc.EditView
import ExclusiveMode
import Firebase.View
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Model
import Model exposing (Msg, commonMsg)
import View.Header
import View.AppDrawer
import Model exposing (..)
import Polymer.Paper as Paper
import Polymer.App as App
import X.Function.Infix exposing (..)
import View.ReminderOverlay exposing (maybe)
import Todo.View
import ViewModel
import WebComponents exposing (onBoolPropertyChanged)
import LaunchBar.View
import GroupDoc.EditView
import Todo.MoreMenu
import View.GetStarted


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

                ExclusiveMode.TaskMoreMenu model ->
                    Todo.MoreMenu.view model

                ExclusiveMode.EditTodoContext form ->
                    Todo.View.contextMenu form appModel

                ExclusiveMode.EditTodoProject form ->
                    Todo.View.projectMenu form appModel

                ExclusiveMode.EditTodoReminder form ->
                    Todo.View.reminderPopup form

                ExclusiveMode.FirstVisit ->
                    View.GetStarted.signInOverlay

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
                , mainContent viewModel m
                ]
            ]


mainContent viewModel model =
    div [ id "main-content" ]
        [ case Model.getMainViewType model of
            EntityListView viewType ->
                EntityList.View.listView viewType model viewModel

            SyncView ->
                CustomSync.view model
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
