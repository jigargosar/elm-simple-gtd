module View.AppDrawer exposing (..)

import AppColors
import AppDrawer.List
import AppUrl
import Document
import Entity
import X.Html exposing (boolProperty)
import OldGroupEntity.ViewModel
import Html.Keyed as Keyed
import Html exposing (Attribute, Html, a, div, hr, node, span, text)
import Html.Attributes exposing (attribute, autofocus, checked, class, classList, href, id, style, tabindex, target, value)
import Html.Events exposing (..)
import X.Keyboard as Keyboard exposing (onEscape, onKeyUp)
import Model exposing (Msg(OnSetViewType), commonMsg)
import String.Extra
import Maybe.Extra as Maybe
import Polymer.Attributes exposing (icon)
import Toolkit.Helpers exposing (..)
import Toolkit.Operators exposing (..)
import X.Debug exposing (tapLog)
import X.Decode exposing (traceDecoder)
import Json.Decode
import Json.Encode
import List.Extra as List
import Model exposing (..)
import Todo
import Polymer.Paper exposing (..)
import Polymer.App as App
import X.Function exposing (..)
import X.Function.Infix exposing (..)
import Model exposing (..)
import View.Shared exposing (..)
import ViewModel
import WebComponents exposing (iconA, onBoolPropertyChanged, paperIconButton)


view : ViewModel.Model -> Model.Model -> Html Msg
view appVM model =
    App.drawer
        [ boolProperty "swipeOpen" True
        , attribute "slot" "drawer"
        ]
        [ App.headerLayout
            [ attribute "has-scrolling-region" ""
            ]
            [ App.header
                [ boolProperty "fixed" True
                , attribute "slot" "header"
                , class "app-header"
                ]
                [ App.toolbar
                    [ style
                        [ "color" => "white"
                        , "background-color" => AppColors.encode appVM.header.backgroundColor
                        ]
                    ]
                    [ div []
                        [ paperIconButton
                            [ iconA "menu"
                            , tabindex -1
                            , attribute "drawer-toggle" ""
                            , onClick Model.ToggleDrawer
                            ]
                            []
                        ]
                    , leftHeader model
                    ]
                ]
            , AppDrawer.List.view appVM model
            ]
        ]


leftHeader m =
    let
        ( t1, t2 ) =
            if m.developmentMode then
                ( "Dev v" ++ m.appVersion, "v" ++ m.appVersion )
            else
                ( "SimpleGTD.com", "v" ++ m.appVersion )
    in
        div [ id "left-header" ]
            [ a [] [ text t1 ]
            , div [ class "small layout horizontal " ]
                [ a [ target "_blank", href AppUrl.changeLogURL, tabindex -1 ]
                    [ "v" ++ m.appVersion |> text ]
                , a [ target "_blank", href AppUrl.newPostURL, tabindex -1 ]
                    [ text "Discuss" ]
                , a [ target "_blank", href AppUrl.contact, tabindex -1 ]
                    [ text "Feedback" ]
                ]
            ]
