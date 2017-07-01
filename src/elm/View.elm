module View exposing (init)

import ActionList.View
import AppDrawer.Model
import AppDrawer.View
import CustomSync
import Entity.View
import Material
import Menu
import X.Html exposing (boolProperty, onClickStopPropagation)
import GroupDoc.EditView
import ExclusiveMode
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Model
import Model exposing (Msg, commonMsg)
import View.Header
import Model exposing (..)
import Todo.Notification.View exposing (maybeOverlay)
import Todo.View
import ViewModel
import WebComponents exposing (onBoolPropertyChanged)
import LaunchBar.View
import GroupDoc.EditView
import Todo.MoreMenu
import View.GetStarted
import View.MainMenu


init model =
    let
        children =
            [ appLayoutView model
            , newTodoFab model
            ]
                ++ overlayViews model
    in
        div [] children


overlayViews appModel =
    let
        editModeOverlayView =
            case Model.getEditMode appModel of
                ExclusiveMode.LaunchBar form ->
                    LaunchBar.View.init form appModel

                ExclusiveMode.TodoMoreMenu model ->
                    Todo.MoreMenu.view model

                ExclusiveMode.EditTodoContext form ->
                    Todo.View.contextMenu form appModel

                ExclusiveMode.EditTodoProject form ->
                    Todo.View.projectMenu form appModel

                ExclusiveMode.EditTodoReminder form ->
                    Todo.View.reminderPopup form

                ExclusiveMode.SignInOverlay ->
                    View.GetStarted.signInOverlay

                ExclusiveMode.Setup form ->
                    View.GetStarted.setup form

                ExclusiveMode.ActionList model ->
                    ActionList.View.init appModel model

                ExclusiveMode.EditProject form ->
                    GroupDoc.EditView.init form

                ExclusiveMode.EditContext form ->
                    GroupDoc.EditView.init form

                ExclusiveMode.EditTodo form ->
                    Todo.View.edit form appModel

                ExclusiveMode.NewTodo form ->
                    Todo.View.new form

                ExclusiveMode.MainMenu menuState ->
                    View.MainMenu.init menuState appModel

                _ ->
                    span [] []
    in
        [ Just editModeOverlayView
        , Todo.Notification.View.maybeOverlay appModel
        ]
            |> List.filterMap identity


appLayoutView m =
    let
        appVM =
            ViewModel.create m

        forceNarrow =
            Model.getLayoutForceNarrow m
    in
        div
            [ id "app-layout"
            , classList
                [ ( "sidebar-overlay", AppDrawer.Model.getIsOverlayOpen m.appDrawerModel )
                ]
            ]
            [ div
                [ id "layout-sidebar", X.Html.onClickStopPropagation Model.noop ]
                [ AppDrawer.View.sidebarHeader appVM m
                , AppDrawer.View.sidebarContent appVM m
                ]
            , div [ id "layout-main", onClick (Model.OnAppDrawerMsg AppDrawer.Model.OnToggleOverlay) ]
                [ View.Header.appMainHeader appVM m
                , div [ id "layout-main-content" ] [ appMainContent appVM m ]
                ]
            ]


appMainContent viewModel model =
    div [ id "main-view-container", X.Html.onClickStopPropagation Model.noop ]
        [ case Model.getMainViewType model of
            EntityListView viewType ->
                Entity.View.list viewType model viewModel

            SyncView ->
                CustomSync.view model
        ]


newTodoFab m =
    Material.fab "add"
        [ id "add-fab"
        , onClick Model.NewTodo
        , tabindex -1
        ]
