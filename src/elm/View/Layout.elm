module View.Layout exposing (..)

import AppDrawer.Model
import AppDrawer.View
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import View.Header
import X.Html exposing (boolProperty, onClickStopPropagation)


appLayoutView config frameVM pageContent =
    let
        layoutSideBarHeader =
            AppDrawer.View.sidebarHeader frameVM

        layoutSideBarContent =
            AppDrawer.View.sidebarContent config frameVM

        layoutMainHeader =
            View.Header.appMainHeader config frameVM

        onClickStopPropagationAV =
            X.Html.onClickStopPropagation config.noop

        layoutMainContent =
            div [ id "layout-main-content" ]
                [ div [ id "page-container" ] [ pageContent ]
                ]

        layoutContent =
            if frameVM.isSideBarOverlayOpen then
                [ div
                    [ id "layout-sidebar", onClickStopPropagationAV ]
                    [ div [ class "bottom-shadow" ] [ layoutSideBarHeader ]
                    , layoutSideBarContent
                    ]
                , div
                    [ id "layout-main"
                    , onClick config.onToggleAppDrawerOverlay
                    ]
                    [ div [ onClickStopPropagationAV ]
                        [ div [ class "bottom-shadow" ] [ layoutMainHeader ]
                        , layoutMainContent
                        ]
                    ]
                ]
            else
                [ div [ class "bottom-shadow" ]
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
        , classList [ ( "sidebar-overlay", frameVM.isSideBarOverlayOpen ) ]
        ]
        layoutContent
