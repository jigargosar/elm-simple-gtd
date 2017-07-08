module View exposing (init)

import AppDrawer.Model
import AppDrawer.Types
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
                ExclusiveMode.XMLaunchBar form ->
                    LaunchBar.View.init form appModel

                ExclusiveMode.XMTodoMoreMenu model ->
                    Todo.MoreMenu.view model

                ExclusiveMode.XMEditTodoContext form ->
                    Todo.View.contextMenu form appModel

                ExclusiveMode.XMEditTodoProject form ->
                    Todo.View.projectMenu form appModel

                ExclusiveMode.XMEditTodoReminder form ->
                    Todo.View.reminderPopup form

                ExclusiveMode.XMSignInOverlay ->
                    View.GetStarted.signInOverlay

                ExclusiveMode.XMSetup form ->
                    View.GetStarted.setup form

                ExclusiveMode.XMEditProject form ->
                    GroupDoc.EditView.init form

                ExclusiveMode.XMEditContext form ->
                    GroupDoc.EditView.init form

                ExclusiveMode.XMEditTodo form ->
                    Todo.View.edit form appModel

                ExclusiveMode.XMNewTodo form ->
                    Todo.View.new form

                ExclusiveMode.XMMainMenu menuState ->
                    View.MainMenu.init menuState appModel

                _ ->
                    span [] []
    in
        [ Just editModeOverlayView
        , Todo.Notification.View.maybeOverlay appModel
        ]
            |> List.filterMap identity



--appLayoutView m =
--    let
--        appVM =
--            ViewModel.create m
--    in
--        div [ class "x-layout" ]
--            [ div [ class "x-sidebar" ]
--                [ div [ class "x-sidebar-header" ]
--                    [ div [ class "x-sidebar-header__inner" ]
--                        [ text "foo" ]
--                    ]
--                ]
--            , div [ class "x-main" ]
--                [ div [ class "x-main-header" ]
--                    [ div [ class "x-main-header__inner" ]
--                        [ div [] [ text "a" ]
--                        ]
--                    ]
--                ]
--            ]


appLayoutView m =
    let
        appVM =
            ViewModel.create m
    in
        -- todo : remove duplication
        if AppDrawer.Model.getIsOverlayOpen m.appDrawerModel then
            div
                [ id "app-layout"
                , classList
                    [ ( "sidebar-overlay", AppDrawer.Model.getIsOverlayOpen m.appDrawerModel )
                    ]
                ]
                [ div
                    [ id "layout-sidebar", X.Html.onClickStopPropagation Model.noop ]
                    [ div [ class "bottom-shadow" ] [ AppDrawer.View.sidebarHeader appVM m ]
                    , AppDrawer.View.sidebarContent appVM m
                    ]
                , div
                    [ id "layout-main"
                    , onClick (Msg.OnAppDrawerMsg AppDrawer.Types.OnToggleOverlay)
                    ]
                    [ div [ X.Html.onClickStopPropagation Model.noop ]
                        [ div [ class "bottom-shadow" ] [ View.Header.appMainHeader appVM m ]
                        , div [ id "layout-main-content" ] [ appMainContent m ]
                        ]
                    ]
                ]
        else
            div
                [ id "app-layout"
                , classList
                    [ ( "sidebar-overlay", AppDrawer.Model.getIsOverlayOpen m.appDrawerModel )
                    ]
                ]
                [ div [ class "bottom-shadow" ]
                    [ AppDrawer.View.sidebarHeader appVM m
                    , View.Header.appMainHeader appVM m
                    ]
                , div
                    [ id "layout-sidebar", X.Html.onClickStopPropagation Model.noop ]
                    [ AppDrawer.View.sidebarContent appVM m
                    ]
                , div
                    [ id "layout-main"
                    , onClick (Msg.OnAppDrawerMsg AppDrawer.Types.OnToggleOverlay)
                    ]
                    [ div [ X.Html.onClickStopPropagation Model.noop ]
                        [ div [ id "layout-main-content" ] [ appMainContent m ]
                        ]
                    ]
                ]


appMainContent model =
    div [ id "main-view-container" ]
        [ case Model.getMainViewType model of
            EntityListView viewType ->
                Entity.View.list viewType model

            SyncView ->
                CustomSync.view model
        ]
