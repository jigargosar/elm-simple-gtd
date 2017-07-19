module View.Layout exposing (..)

import AppDrawer.Model
import AppDrawer.Types
import AppDrawer.View
import Entity.View
import Model.ViewType
import Types.ViewType exposing (ViewType(..))
import View.CustomSync
import X.Html exposing (boolProperty, onClickStopPropagation)
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import View.Header
import ViewModel
import View.Mat


appLayoutView config model =
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
                    [ id "layout-sidebar", X.Html.onClickStopPropagation config.noop ]
                    [ div [ class "bottom-shadow" ] [ AppDrawer.View.sidebarHeader appVM model ]
                    , AppDrawer.View.sidebarContent appVM model
                    ]
                , div
                    [ id "layout-main"
                    , onClick config.onToggleAppDrawerOverlay
                    ]
                    [ div [ X.Html.onClickStopPropagation config.noop ]
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
                    [ id "layout-sidebar", X.Html.onClickStopPropagation config.noop ]
                    [ AppDrawer.View.sidebarContent appVM model
                    ]
                , div
                    [ id "layout-main"
                    , onClick (config.onToggleAppDrawerOverlay)
                    ]
                    [ div [ X.Html.onClickStopPropagation config.noop ]
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
