module View exposing (init)

import ActionList.View
import AppDrawer.Model
import AppDrawer.View
import CustomSync
import Entity.View
import Mat
import Material.Options
import Menu
import Msg exposing (ViewType(..))
import X.Html exposing (boolProperty, onClickStopPropagation)
import ExclusiveMode
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Model
import View.Header
import Todo.Notification.View exposing (maybeOverlay)
import Todo.View
import ViewModel
import WebComponents exposing (onBoolPropertyChanged)
import LaunchBar.View
import GroupDoc.EditView
import Todo.MoreMenu
import View.GetStarted
import View.MainMenu
import View.Mat


init model =
    let
        children =
            [ appLayoutView model
            , View.Mat.newTodoFab model
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
    in
        div [ class "layout" ]
            [ div [ class "layout--sidebar" ] []
            , div [ class "layout--main" ] []
            ]



--appLayoutView m =
--    let
--        appVM =
--            ViewModel.create m
--    in
--        -- todo : remove duplication
--        if AppDrawer.Model.getIsOverlayOpen m.appDrawerModel then
--            div
--                [ id "app-layout"
--                , classList
--                    [ ( "sidebar-overlay", AppDrawer.Model.getIsOverlayOpen m.appDrawerModel )
--                    ]
--                ]
--                [ div
--                    [ id "layout-sidebar", X.Html.onClickStopPropagation Model.noop ]
--                    [ div [ class "bottom-shadow" ] [ AppDrawer.View.sidebarHeader appVM m ]
--                    , AppDrawer.View.sidebarContent appVM m
--                    ]
--                , div
--                    [ id "layout-main"
--                    , onClick (Msg.OnAppDrawerMsg AppDrawer.Model.OnToggleOverlay)
--                    ]
--                    [ div [ X.Html.onClickStopPropagation Model.noop ]
--                        [ div [ class "bottom-shadow" ] [ View.Header.appMainHeader appVM m ]
--                        , div [ id "layout-main-content" ] [ appMainContent m ]
--                        ]
--                    ]
--                ]
--        else
--            div
--                [ id "app-layout"
--                , classList
--                    [ ( "sidebar-overlay", AppDrawer.Model.getIsOverlayOpen m.appDrawerModel )
--                    ]
--                ]
--                [ div [ class "bottom-shadow" ]
--                    [ AppDrawer.View.sidebarHeader appVM m
--                    , View.Header.appMainHeader appVM m
--                    ]
--                , div
--                    [ id "layout-sidebar", X.Html.onClickStopPropagation Model.noop ]
--                    [ AppDrawer.View.sidebarContent appVM m
--                    ]
--                , div
--                    [ id "layout-main"
--                    , onClick (Msg.OnAppDrawerMsg AppDrawer.Model.OnToggleOverlay)
--                    ]
--                    [ div [ X.Html.onClickStopPropagation Model.noop ]
--                        [ div [ id "layout-main-content" ] [ appMainContent m ]
--                        ]
--                    ]
--                ]


appMainContent model =
    div [ id "main-view-container" ]
        [ case Model.getMainViewType model of
            EntityListView viewType ->
                Entity.View.list viewType model

            SyncView ->
                CustomSync.view model
        ]
