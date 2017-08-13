module Views.Frame exposing (..)

import AppDrawer.View
import Color
import Html exposing (text)
import Mat
import Material.Button
import Material.Options exposing (..)
import Material.Tooltip
import View.Header
import View.Overlays


appLayoutView config frameVM pageContent =
    let
        layoutSideBarHeader =
            AppDrawer.View.sidebarHeader frameVM

        layoutSideBarContent =
            AppDrawer.View.sidebarContent config frameVM

        layoutMainHeader =
            View.Header.appMainHeader config frameVM

        onClickStopPropagationAV =
            Mat.onClickStopPropagation config.noop

        layoutMainContent =
            div [ id "layout-main-content" ]
                [ div [ id "page-container" ] [ pageContent ]
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


newTodoFab config m =
    div [ cs "primary-fab-container" ]
        [ div [ Material.Tooltip.attach config.onMdl [ 0 ] ]
            [ Mat.fab config.onMdl
                m.mdl
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
            m.mdl
            [ Material.Tooltip.left ]
            [ div [ cs "mdl-typography--body-2" ] [ text "Quick Add Task (q)" ]
            , div [ cs "mdl-typography--body-1" ] [ text "Add To Inbox (i)" ]
            ]
        ]


init frameVM =
    div [ cs "mdl-typography--body-1" ]
        ([ appLayoutView frameVM.config frameVM frameVM.pageContent
         , newTodoFab frameVM.config frameVM.model
         ]
            ++ View.Overlays.overlayViews frameVM.config frameVM.model
        )
