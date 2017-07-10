module View exposing (init)

import AppDrawer.Model
import AppDrawer.Types
import AppDrawer.View
import CustomSync
import Entity.View
import ExclusiveMode.Types exposing (ExclusiveMode(..))
import Model.ViewType
import Msg
import X.Html exposing (boolProperty, onClickStopPropagation)
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Model
import View.Header
import Todo.Notification.View exposing (maybeOverlay)
import Todo.View
import ViewModel
import LaunchBar.View
import GroupDoc.EditView
import Todo.MoreMenu
import View.GetStarted
import View.MainMenu
import View.Mat
import ViewType exposing (ViewType(EntityListView, SyncView))


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
            case appModel.editMode of
                XMLaunchBar form ->
                    LaunchBar.View.init form appModel

                XMTodoMoreMenu model ->
                    Todo.MoreMenu.view model

                XMEditTodoContext form ->
                    Todo.View.contextMenu form appModel

                XMEditTodoProject form ->
                    Todo.View.projectMenu form appModel

                XMEditTodoReminder form ->
                    Todo.View.reminderPopup form

                XMSignInOverlay ->
                    View.GetStarted.signInOverlay

                XMSetup form ->
                    View.GetStarted.setup form

                XMEditProject form ->
                    GroupDoc.EditView.init form

                XMEditContext form ->
                    GroupDoc.EditView.init form

                XMEditTodo form ->
                    Todo.View.edit form appModel

                XMNewTodo form ->
                    Todo.View.new form

                XMMainMenu menuState ->
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
        [ case Model.ViewType.getMainViewType model of
            EntityListView viewType ->
                Entity.View.list viewType model

            SyncView ->
                CustomSync.view model
        ]
