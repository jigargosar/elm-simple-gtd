module View exposing (init)

import AppDrawer.Model
import AppDrawer.Types
import AppDrawer.View
import Entity.View
import ExclusiveMode.Types exposing (..)
import Model.ViewType
import Msg
import Todo.FormTypes exposing (..)
import View.CustomSync
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
import GroupDoc.FormView
import View.GetStarted
import View.MainMenu
import View.Mat
import Types.View exposing (ViewType(EntityListView, SyncView))


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
                    -- todo extract this into todo view
                    case form.mode of
                        TFM_Edit editMode ->
                            case editMode of
                                ETFM_EditTodoContext ->
                                    Todo.View.editTodoContextPopupView form appModel

                                ETFM_EditTodoProject ->
                                    Todo.View.editTodoProjectPopupView form appModel

                                ETFM_EditTodoReminder ->
                                    Todo.View.editTodoSchedulePopupView form

                                ETFM_EditTodoText ->
                                    Todo.View.editTodoTextView form appModel

                        TFM_Add addMode ->
                            case addMode of
                                ATFM_SetupFirstTodo ->
                                    View.GetStarted.setup form

                                ATFM_AddWithFocusInEntityAsReference ->
                                    Todo.View.new form

                                ATFM_AddToInbox ->
                                    Todo.View.new form

                XMSignInOverlay ->
                    View.GetStarted.signInOverlay

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
                View.CustomSync.view model
        ]
