module View exposing (init)

import AppDrawer.Model
import AppDrawer.Types
import AppDrawer.View
import Entity.View
import ExclusiveMode.Types exposing (..)
import Lazy exposing (Lazy)
import Model.ViewType
import Msg
import Todo.FormTypes exposing (..)
import Todo.GroupEditView
import TodoMsg
import View.CustomSync
import X.Html exposing (boolProperty, onClickStopPropagation)
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import View.Header
import Todo.Notification.View exposing (maybeOverlay)
import Todo.View
import ViewModel
import LaunchBar.View
import GroupDoc.FormView
import View.GetStarted
import View.MainMenu
import View.Mat
import Types.ViewType exposing (ViewType(EntityListView, SyncView))
import View.Overlays


init model =
    let
        alv =
            appLayoutView model

        children =
            [ alv
            , View.Mat.newTodoFab alv model
            ]
                ++ View.Overlays.overlayViews config model
    in
        div [ class "mdl-typography--body-1" ] children


config =
    { onSetProject = TodoMsg.onSetProjectAndMaybeSelection
    , onSetContext = TodoMsg.onSetContextAndMaybeSelection
    , onSetTodoFormMenuState = TodoMsg.onSetTodoFormMenuState
    , noop = Msg.noop
    , revertExclusiveMode = Msg.revertExclusiveMode
    , onSetTodoFormText = TodoMsg.onSetTodoFormText
    , onToggleDeleted = TodoMsg.onToggleDeleted
    , onSetTodoFormReminderDate = TodoMsg.onSetTodoFormReminderDate
    , onSetTodoFormReminderTime = TodoMsg.onSetTodoFormReminderTime
    , onSaveExclusiveModeForm = Msg.onSaveExclusiveModeForm
    , onEntityUpdateMsg = Msg.onEntityUpdateMsg
    , onMainMenuStateChanged = Msg.onMainMenuStateChanged
    , onSignIn = Msg.onSignIn
    , onSignOut = Msg.onSignOut
    , onLaunchBarMsg = Msg.OnLaunchBarMsg
    , onFirebaseMsg = Msg.OnFirebaseMsg
    , onReminderOverlayAction = TodoMsg.onReminderOverlayAction
    }


appLayoutView model =
    let
        appVM =
            ViewModel.create model
    in
        if AppDrawer.Model.getIsOverlayOpen model.appDrawerModel then
            div
                [ id "app-layout"
                , classList
                    [ ( "sidebar-overlay", AppDrawer.Model.getIsOverlayOpen model.appDrawerModel )
                    ]
                ]
                [ div
                    [ id "layout-sidebar", X.Html.onClickStopPropagation Msg.noop ]
                    [ div [ class "bottom-shadow" ] [ AppDrawer.View.sidebarHeader appVM model ]
                    , AppDrawer.View.sidebarContent appVM model
                    ]
                , div
                    [ id "layout-main"
                    , onClick (Msg.OnAppDrawerMsg AppDrawer.Types.OnToggleOverlay)
                    ]
                    [ div [ X.Html.onClickStopPropagation Msg.noop ]
                        [ div [ class "bottom-shadow" ] [ View.Header.appMainHeader appVM model ]
                        , div [ id "layout-main-content" ] [ appMainContent model ]
                        ]
                    ]
                ]
        else
            div
                [ id "app-layout"
                , classList
                    [ ( "sidebar-overlay", AppDrawer.Model.getIsOverlayOpen model.appDrawerModel )
                    ]
                ]
                [ div [ class "bottom-shadow" ]
                    [ AppDrawer.View.sidebarHeader appVM model
                    , View.Header.appMainHeader appVM model
                    ]
                , div
                    [ id "layout-sidebar", X.Html.onClickStopPropagation Msg.noop ]
                    [ AppDrawer.View.sidebarContent appVM model
                    ]
                , div
                    [ id "layout-main"
                    , onClick (Msg.OnAppDrawerMsg AppDrawer.Types.OnToggleOverlay)
                    ]
                    [ div [ X.Html.onClickStopPropagation Msg.noop ]
                        [ div [ id "layout-main-content" ] [ appMainContent model ]
                        ]
                    ]
                ]


appMainContent model =
    div [ id "main-view-container" ]
        [ case Model.ViewType.getMainViewType model of
            EntityListView viewType ->
                Entity.View.list viewType model

            SyncView ->
                View.CustomSync.view model
        ]
