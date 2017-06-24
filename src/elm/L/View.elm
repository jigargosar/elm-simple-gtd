module L.View exposing (..)

import Material
import Toolkit.Helpers exposing (..)
import Toolkit.Operators exposing (..)
import X.Function exposing (..)
import X.Function.Infix exposing (..)
import List.Extra as List
import Maybe.Extra as Maybe
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)


view model =
    div [ id "landing" ]
        [ navHeader
        , banner
        , overview
        ]


navHeader =
    div [ class "navbar-fixed" ]
        [ nav []
            [ div [ class "nav-wrapper" ]
                [ a [ class "brand-logo", href "/?landing=true" ]
                    [ div [ class "layout horizontal center" ]
                        [ img [ src "/logo.png", class "logo" ] []
                        , div [ class "app-name" ] [ text "Simple GTD" ]
                        ]
                    ]
                , ul [ class "right hide-on-small-and-down" ]
                    [ {- li [] [ a [] [ text "Open Source" ] ]
                         ,
                      -}
                      li [] [ a [] [ text "Sign In" ] ]
                    , li [] [ a [ class "primary-action" ] [ text "Get Started" ] ]
                    ]
                ]
            ]
        ]


banner =
    div [ class "banner" ]
        [ div [ class "container" ]
            [ div [ class "row" ]
                [ div [ class "col s12 m6" ]
                    [ h3 [] [ text "Simply Get To Done" ]
                    , h5 [] [ text "Achieve more, with mind like water" ]
                    , a [ class "primary-action" ] [ text "Get Started - It's Free" ]
                    , p [ class "" ] [ text "No sign up required!" ]
                    ]
                ]
            ]
        ]


bannerMock =
    img [ src "https://d3ptyyxy2at9ui.cloudfront.net/bc51cd8ccfb3787ee54ad263924a1a0a.jpg", class "responsive-img" ] []


overview =
    div [ class "container overview center" ]
        [ div [ class "row" ]
            [ section [ class "section" ]
                [ h5 []
                    [ header [] [ text "Simply start accomplishing more with peace of mind and focus" ]
                    ]
                , p [] [ text "Work offline, in browser on any platform. And your work syncs automatically." ]
                ]
            ]
        , primaryFeatures
        ]


primaryFeatures =
    let
        featureClass =
            "feature col s12 m4"
    in
        div [ class "row features primary" ]
            [ div [ class featureClass ]
                [ Material.icon "palette"
                , h5 [] [ text "Minimalistic Design" ]
                ]
            , div [ class featureClass ]
                [ Material.icon "sync"
                , h5 [] [ text "Works offline" ]
                ]
            , div [ class featureClass ]
                [ Material.icon "nature_people"
                , h5 [] [ text "Free and Open Source" ]
                ]
            ]
