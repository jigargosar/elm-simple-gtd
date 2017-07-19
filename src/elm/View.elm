module View exposing (init)

import AppDrawer.Model
import AppDrawer.Types
import AppDrawer.View
import Entity.View
import ExclusiveMode.Types exposing (..)
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


init model =
    let
        alv =
            appLayoutView model

        children =
            [ alv
            , View.Mat.newTodoFab alv model
            ]
                ++ overlayViews model
    in
        div [ class "mdl-typography--body-1" ] children


overlayViews appModel =
    let
        def =
            span [] []

        editModeOverlayView =
            case appModel.editMode of
                XMLaunchBar launchBar ->
                    LaunchBar.View.init launchBar
                        |> Html.map Msg.OnLaunchBarMsg

                XMTodoForm form ->
                    let
                        config =
                            { onSetProject = TodoMsg.onSetProjectAndMaybeSelection
                            , onSetContext = TodoMsg.onSetContextAndMaybeSelection
                            , onSetTodoFormMenuState = TodoMsg.onSetTodoFormMenuState
                            , noop = Msg.noop
                            , revertExclusiveMode = Msg.revertExclusiveMode
                            , onSetTodoFormText = TodoMsg.onSetTodoFormText
                            , onEntityUpdateMsg = Msg.onEntityUpdateMsg
                            , onSetTodoFormReminderDate = TodoMsg.onSetTodoFormReminderDate
                            , onSetTodoFormReminderTime = TodoMsg.onSetTodoFormReminderTime
                            , onSaveExclusiveModeForm = Msg.onSaveExclusiveModeForm
                            }
                    in
                        case form.mode of
                            TFM_Edit editMode ->
                                case editMode of
                                    ETFM_EditTodoContext ->
                                        Todo.GroupEditView.context config form appModel

                                    ETFM_EditTodoProject ->
                                        Todo.GroupEditView.project config form appModel

                                    ETFM_EditTodoSchedule ->
                                        Todo.View.editTodoSchedulePopupView config form

                                    ETFM_EditTodoText ->
                                        Todo.View.editTodoTextView config form

                            TFM_Add addMode ->
                                case addMode of
                                    ATFM_SetupFirstTodo ->
                                        View.GetStarted.setup config form

                                    ATFM_AddWithFocusInEntityAsReference ->
                                        Todo.View.new config form

                                    ATFM_AddToInbox ->
                                        Todo.View.new config form

                XMSignInOverlay ->
                    View.GetStarted.signInOverlay
                        |> Html.map Msg.OnFirebaseMsg

                XMGroupDocForm form ->
                    GroupDoc.FormView.init form

                XMMainMenu menuState ->
                    View.MainMenu.init menuState appModel

                _ ->
                    def
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
