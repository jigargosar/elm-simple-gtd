module View.Header exposing (appMainHeader)

import AppColors
import Mat
import Firebase
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Todo.TimeTracker.View
import Toolkit.Operators exposing (..)
import X.Function.Infix exposing (..)
import X.List


appMainHeader config viewModel m =
    let
        content =
            Todo.TimeTracker.View.maybe config m
                ?|> X.List.singleton
                ?= titleHeaderContent viewModel
    in
        div
            [ id "layout-main-header"
            , style
                [ "color" => "white"
                , "background-color" => AppColors.encode viewModel.header.backgroundColor
                ]
            ]
            (headerWithContent config content m)


titleHeaderContent viewModel =
    let
        titleText =
            viewModel.viewName
    in
        [ h5 [ class "ellipsis title", title titleText ] [ titleText |> text ]
        ]


headerWithContent config content m =
    let
        menuButton =
            Mat.headerIconBtn config.onMdl
                m.mdl
                [ Mat.resourceId "center-header-menu"
                , Mat.tabIndex -1
                , Mat.cs "menu-btn"
                , Mat.onClickStopPropagation (config.onToggleAppDrawerOverlay)
                ]
                [ Mat.icon "menu" ]
    in
        [ menuButton
        , div [ class "flex-auto font-nowrap" ] content
        , div [ id "main-menu-button", onClick config.onShowMainMenu ] [ menuIcon config m ]
        ]


menuIcon config m =
    case Firebase.getMaybeUserProfile m of
        Nothing ->
            Mat.headerIconBtn config.onMdl
                m.mdl
                [ Mat.resourceId "account-menu-not-signed-in"
                , Mat.tabIndex -1
                ]
                [ Mat.icon "account_circle" ]

        Just { photoURL } ->
            img
                [ src photoURL
                , class "account"
                ]
                []
