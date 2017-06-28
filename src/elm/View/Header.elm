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
import Polymer.App as App
import Polymer.Paper as Paper
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Todo.TimeTracker.View
import Toolkit.Operators exposing (..)
import X.Function.Infix exposing (..)
import WebComponents exposing (..)
import X.List


init viewModel m =
    let
        layoutAttributes =
            if Model.isLayoutAutoNarrow m then
                [ attribute "condenses" ""
                , attribute "reveals" ""
                ]
            else
                [ attribute "fixed" "" ]

        attributes =
            [ id "main-header"
            , attribute "slot" "header"
            , attribute "effects" "waterfall"
            ]
                ++ layoutAttributes
    in
        App.header
            attributes
            [ App.toolbar
                [ style
                    [ "color" => "white"
                    , "background-color" => AppColors.encode viewModel.header.backgroundColor
                    ]
                ]
                [ appMainHeader viewModel m ]
            ]


appMainHeader viewModel m =
    let
        content =
            Todo.TimeTracker.View.maybe m
                ?|> X.List.singleton
                ?= titleHeaderContent viewModel m
    in
        div
            [ id "app-main-header"
            , style
                [ "color" => "white"
                , "background-color" => AppColors.encode viewModel.header.backgroundColor
                ]
            , X.Html.onClickStopPropagation Model.noop
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
            --            paperIconButton
            --                    [ iconA "menu"
            --                    , tabindex -1
            --                    , attribute "drawer-toggle" ""
            --                    , onClick Model.ToggleDrawer
            --                    , class "hide-when-wide"
            --                    ]
            --                    []
            Material.iconButton "menu"
                [ class "menu-btn"
                , tabindex -1
                , onClick (Model.OnAppDrawerMsg AppDrawer.Model.OnToggleOverlay)
                ]
    in
        [ menuButton
        , div [ class "flex-auto" ] content
        , menu m
        ]


menu m =
    let
        maybeUserProfile =
            Model.getMaybeUserProfile m

        userAccountAttribute =
            maybeUserProfile
                ?|> (Firebase.getPhotoURL >> attribute "src")
                ?= iconA "account-circle"

        userSignInLink =
            maybeUserProfile
                ?|> (\_ -> Paper.item [ onClick Model.OnSignOut ] [ text "SignOut" ])
                ?= Paper.item [ onClick Model.OnSignIn ] [ text "SignIn" ]
    in
        Paper.menuButton
            [ dynamicAlign
            , boolProperty "noOverlap" True
            , boolProperty "closeOnActivate" True
            ]
            [ Html.node "iron-icon"
                [ userAccountAttribute
                , class "account"
                , slotDropdownTrigger
                ]
                []
            , Paper.listbox [ class "", slotDropdownContent ]
                [ userSignInLink
                , itemLink AppUrl.forumsURL "Forums/Discuss"
                , itemLink AppUrl.changeLogURL
                    ("Changelog v" ++ m.appVersion)
                , itemLink AppUrl.github "Github"
                ]
            ]


itemLink url content =
    Paper.item []
        [ Paper.itemBody []
            [ a
                [ target "_blank"
                , href url
                ]
                [ text content ]
            ]
        ]
