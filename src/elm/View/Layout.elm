module View.Layout exposing (..)

import AppDrawer.Model
import AppDrawer.View
import Entity.ListView
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Page
import View.CustomSync
import View.Header
import X.Html exposing (boolProperty, onClickStopPropagation)


appLayoutView config appVM model pageContent =
    let
        layoutSideBarHeader =
            AppDrawer.View.sidebarHeader appVM model

        layoutSideBarContent =
            AppDrawer.View.sidebarContent config appVM model

        layoutMainHeader =
            View.Header.appMainHeader config appVM model

        mainViewContainer =
            div [ id "main-view-container" ]
                [ pageContent
                ]

        isOverlayOpen =
            AppDrawer.Model.getIsOverlayOpen model.appDrawerModel

        onClickStopPropagationAV =
            X.Html.onClickStopPropagation config.noop

        layoutMainContent =
            div [ id "layout-main-content" ] [ mainViewContainer ]
    in
    if isOverlayOpen then
        div
            [ id "app-layout"
            , classList [ ( "sidebar-overlay", isOverlayOpen ) ]
            ]
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
        div
            [ id "app-layout"
            , classList [ ( "sidebar-overlay", isOverlayOpen ) ]
            ]
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
                [ div [ onClickStopPropagationAV ]
                    [ layoutMainContent
                    ]
                ]
            ]
