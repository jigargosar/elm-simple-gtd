module View.Header exposing (..)

import AppColors
import AppUrl

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
import XList


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
                (headerView viewModel m)
            ]


headerView viewModel m =
    let
        content =
            Todo.TimeTracker.View.maybe m
                ?|> XList.singleton
                ?= titleHeaderContent viewModel m
    in
        headerWithContent content m


titleHeaderContent viewModel m =
    let
        titleText =
            viewModel.viewName
    in
        [ h5 [ class "ellipsis title", title titleText ] [ titleText |> text ]
        ]


headerWithContent content m =
    [ paperIconButton
        [ iconA "menu"
        , tabindex -1
        , attribute "drawer-toggle" ""
        , onClick Model.ToggleDrawer
        , class "hide-when-wide"
        ]
        []
    , div [ class "flex-auto", style [ "max-width" => "80%" ] ] content
    , div [ class "flex-auto" ] []
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
