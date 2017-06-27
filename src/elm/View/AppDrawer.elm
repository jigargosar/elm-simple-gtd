module View.AppDrawer exposing (..)

import AppColors
import AppDrawer.View
import AppUrl
import X.Html exposing (boolProperty)
import Html exposing (Attribute, Html, a, div, h5, hr, node, span, text)
import Html.Attributes exposing (attribute, autofocus, checked, class, classList, href, id, style, tabindex, target, value)
import Html.Events exposing (..)
import Model exposing (Msg(OnSetViewType), commonMsg)
import Model exposing (..)
import Polymer.App as App
import X.Function.Infix exposing (..)
import Model exposing (..)
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
                    , leftHeader appVM model
                    ]
                ]
            , AppDrawer.View.list appVM model
            ]
        ]


leftHeader appVM m =
    let
        ( t1, t2 ) =
            if m.developmentMode then
                ( "Dev v" ++ m.appVersion, "v" ++ m.appVersion )
            else
                ( "SimpleGTD.com", "v" ++ m.appVersion )
    in
        div
            [ id "left-header"
            , style
                [ "color" => "white"
                , "background-color" => AppColors.encode appVM.header.backgroundColor
                ]
            ]
            [ h5 [ href AppUrl.landing ] [ text t1 ]
            , div [ class "small layout horizontal " ]
                [ a [ target "_blank", href AppUrl.changeLogURL, tabindex -1 ]
                    [ "v" ++ m.appVersion |> text ]
                , a [ target "_blank", href AppUrl.newPostURL, tabindex -1 ]
                    [ text "Discuss" ]
                , a [ target "_blank", href AppUrl.contact, tabindex -1 ]
                    [ text "Feedback" ]
                ]
            ]
