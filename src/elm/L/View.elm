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
        , footerView
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
        descriptionLine desc =
            p [] [ text desc ]

        feature ( iconName, heading, desc ) =
            div [ class "feature col s12 m4 center" ]
                [ Material.icon iconName
                , h5 [] [ text heading ]
                , div [] (desc .|> descriptionLine)
                ]

        seamlessly =
            ""

        list =
            [ ( "palette"
              , "Minimalistic Design"
              , [ "Focus on doing with our simple & beautiful interface"
                , "Less is more, that's our philosophy"
                ]
              )
            , ( "sync"
              , "Work seamlessly"
              , [ "We will sync automatically when you get online"
                , "Additionally you never have to worry about upgrading, it just happens automatically"
                ]
              )
            , ( "nature_people"
              , "Free and Open Source"
              , [ "And we are proud of it"
                , "You can contribute, tinker, learn, host yourself, sky is the limit"
                , "No more worries about propriety software"
                ]
              )
            ]
    in
        div [ class "row features primary" ]
            (list .|> feature)


footerView =
    footer [ class "page-footer" ]
        [ div [ class "container footer" ]
            [ div [ class "row" ]
                [ div [ class "col s12 m6 offset-m2" ]
                    [ {- h5 [] [ text "LEARN MORE" ]
                         ,
                      -}
                      learnMoreLinks
                    ]

                {- , div [ class "col s12 m6" ]
                   [ h5 [] [ text "HELP CENTER" ]
                   , helpCenterLinks
                   ]
                -}
                ]
            ]
        , div
            [ class "footer-copyright" ]
            [ div [ class "container" ] [ text "© 2017 Copyright simplegtd.com" ] ]
        ]


learnMoreLinks =
    let
        linkV ( hrefV, textV ) =
            li [] [ a [ class "white-text", href hrefV, target "_blank" ] [ text textV ] ]
    in
        ul []
            [ linkV ( "https://github.com/jigargosar/elm-simple-gtd", "Github" )
            , linkV ( "", "Github" )
            , linkV ( "", "Github" )
            , linkV ( "", "Github" )
            ]


helpCenterLinks =
    let
        linkV ( hrefV, textV ) =
            li [] [ a [ class "white-text", href hrefV ] [ text textV ] ]
    in
        ul []
            [ linkV ( "", "Github" )
            , linkV ( "", "Github" )
            , linkV ( "", "Github" )
            , linkV ( "", "Github" )
            , linkV ( "", "Github" )
            , linkV ( "", "Github" )
            , linkV ( "", "Github" )
            , linkV ( "", "Github" )
            , linkV ( "", "Github" )
            , linkV ( "", "Github" )
            ]
