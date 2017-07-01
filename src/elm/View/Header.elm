module View.Header exposing (..)

import AppColors
import AppDrawer.Model
import AppUrl
import Material
import X.Html exposing (boolProperty)
import Firebase
import Model
import Model exposing (Model)
import Model exposing (Msg)
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Todo.TimeTracker.View
import Toolkit.Operators exposing (..)
import X.Function.Infix exposing (..)
import WebComponents exposing (..)
import X.List


appMainHeader viewModel m =
    let
        content =
            Todo.TimeTracker.View.maybe m
                ?|> X.List.singleton
                ?= titleHeaderContent viewModel m
    in
        div
            [ id "layout-main-header"
            , style
                [ "color" => "white"
                , "background-color" => AppColors.encode viewModel.header.backgroundColor
                ]
            ]
            (headerWithContent content m)


titleHeaderContent viewModel m =
    let
        titleText =
            viewModel.viewName
    in
        [ h5 [ class "ellipsis title", title titleText ] [ titleText |> text ]
        ]


headerWithContent content m =
    let
        menuButton =
            Material.iconButton "menu"
                [ class "menu-btn"
                , tabindex -1
                , onClick (Model.OnAppDrawerMsg AppDrawer.Model.OnToggleOverlay)
                ]
    in
        [ menuButton
        , div [ class "flex-auto font-nowrap" ] content
        , menu m
        ]


menu m =
    let
        maybeUserProfile =
            Model.getMaybeUserProfile m

        menuIcon =
            case maybeUserProfile of
                Nothing ->
                    Material.iconButton "account_circle"
                        [ class "account"
                        ]

                Just profile ->
                    img
                        [ profile |> Firebase.getPhotoURL >> src
                        , class "account"
                        ]
                        []
    in
        div [ id "main-menu-button", onClick Model.OnShowMainMenu ] [ menuIcon ]
