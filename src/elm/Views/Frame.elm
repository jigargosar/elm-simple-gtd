module Views.Frame exposing (..)

import AppDrawer.View
import Color
import Colors
import ExclusiveMode.Types exposing (..)
import GroupDoc.FormView
import Html exposing (text)
import Html.Attributes exposing (class, src, title)
import Mat
import Material.Button
import Material.Options exposing (..)
import Material.Tooltip
import Todo.FormTypes exposing (..)
import Todo.GroupEditView
import Todo.ReminderOverlay.View exposing (maybeOverlay)
import Todo.View
import Views.FBSignInOverlay
import Views.MainMenuOverlay
import Views.TDGetStartedOverlay
import X.Function.Infix exposing (..)


init frameVM =
    div [ cs "mdl-typography--body-1" ]
        ([ appLayoutView frameVM
         , newTodoFab frameVM.config
         ]
            ++ overlayViews frameVM
        )


appMainHeader config frameVM =
    div
        [ id "layout-main-header"
        , css "color" "white"
        , css "background-color" (Colors.toRBGAString frameVM.headerBackgroundColor)
        ]
        [ sidebarMenuButton config frameVM
        , div [ cs "flex-auto font-nowrap" ] [ headerTitle frameVM ]
        , div [ id "main-menu-button", onClick config.onShowMainMenu ]
            [ mainMenuProfileIcon config frameVM ]
        ]


headerTitle frameVM =
    Html.h5 [ class "ellipsis title", title frameVM.mainHeaderTitle ]
        [ text frameVM.mainHeaderTitle ]


sidebarMenuButton config frameVM =
    Mat.headerIconBtn config.onMdl
        frameVM.mdl
        [ Mat.resourceId "center-header-menu"
        , Mat.tabIndex -1
        , Mat.cs "menu-btn"
        , Mat.onClickStopPropagation config.onToggleAppDrawerOverlay
        ]
        [ Mat.icon "menu" ]


mainMenuProfileIcon config frameVM =
    case frameVM.maybeUser of
        Nothing ->
            Mat.headerIconBtn config.onMdl
                frameVM.mdl
                [ Mat.resourceId "account-menu-not-signed-in"
                , Mat.tabIndex -1
                ]
                [ Mat.icon "account_circle" ]

        Just { photoURL } ->
            img
                [ cs "account"
                ]
                [ src photoURL ]


overlayViews frameVM =
    let
        config =
            frameVM.config

        appModel =
            frameVM.model

        def =
            text ""

        editModeOverlayView =
            case appModel.editMode of
                XMTodoForm form ->
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
                                    Views.TDGetStartedOverlay.setup config form

                                ATFM_AddWithFocusInEntityAsReference _ ->
                                    Todo.View.new config form

                                ATFM_AddToInbox ->
                                    Todo.View.new config form

                XMSignInOverlay ->
                    Views.FBSignInOverlay.init config

                XMGroupDocForm form ->
                    GroupDoc.FormView.init config form

                XMMainMenu menuState ->
                    Views.MainMenuOverlay.view config menuState appModel

                XMNone ->
                    def
    in
    [ Just editModeOverlayView
    , Todo.ReminderOverlay.View.maybeOverlay config appModel
    ]
        |> List.filterMap identity


appLayoutView frameVM =
    let
        config =
            frameVM.config

        layoutSideBarHeader =
            AppDrawer.View.sidebarHeader frameVM

        layoutSideBarContent =
            AppDrawer.View.sidebarContent config frameVM

        layoutMainHeader =
            appMainHeader config frameVM

        onClickStopPropagationAV =
            Mat.onClickStopPropagation config.noop

        layoutMainContent =
            div [ id "layout-main-content" ]
                [ div [ id "page-container" ] [ frameVM.pageContent ]
                ]

        layoutContent =
            if frameVM.isSideBarOverlayOpen then
                [ div
                    [ id "layout-sidebar", onClickStopPropagationAV ]
                    [ div [ cs "bottom-shadow" ] [ layoutSideBarHeader ]
                    , layoutSideBarContent
                    ]
                , div
                    [ id "layout-main"
                    , onClick config.onToggleAppDrawerOverlay
                    ]
                    [ div [ onClickStopPropagationAV ]
                        [ div [ cs "bottom-shadow" ] [ layoutMainHeader ]
                        , layoutMainContent
                        ]
                    ]
                ]
            else
                [ div [ cs "bottom-shadow" ]
                    [ layoutSideBarHeader
                    , layoutMainHeader
                    ]
                , div
                    [ id "layout-sidebar", onClickStopPropagationAV ]
                    [ layoutSideBarContent
                    ]
                , div
                    [ id "layout-main"
                    , onClick config.onToggleAppDrawerOverlay
                    ]
                    [ div [ onClickStopPropagationAV ] [ layoutMainContent ]
                    ]
                ]
    in
    div
        [ id "app-layout"
        , if frameVM.isSideBarOverlayOpen then
            cs "sidebar-overlay"
          else
            nop
        ]
        layoutContent


newTodoFab config =
    div [ cs "primary-fab-container" ]
        [ div [ Material.Tooltip.attach config.onMdl [ 0 ] ]
            [ Mat.fab config.onMdl
                config.mdl
                [ id "add-fab"
                , Material.Button.colored
                , Mat.onClickStopPropagation
                    config.onStartAddingTodoWithFocusInEntityAsReference
                , Mat.resourceId "add-todo-fab"
                ]
                [ Mat.iconM { name = "add", color = Color.white } ]
            ]
        , Material.Tooltip.render config.onMdl
            [ 0 ]
            config.mdl
            [ Material.Tooltip.left ]
            [ div [ cs "mdl-typography--body-2" ] [ text "Quick Add Task (q)" ]
            , div [ cs "mdl-typography--body-1" ] [ text "Add To Inbox (i)" ]
            ]
        ]
