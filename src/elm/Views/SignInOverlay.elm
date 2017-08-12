module Views.SignInOverlay exposing (..)

import AppUrl
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Update.Firebase exposing (..)
import X.Html exposing (onClickStopPropagation)
import X.Keyboard


signInOverlay =
    div
        [ class "overlay"
        , onClickStopPropagation OnFBNoOP
        ]
        [ div [ class "modal fixed-center" ]
            [ div [ class "modal-content" ]
                [ h5 [ class "" ]
                    [ text "One click sign in" ]
                , div [ class "section layout horizontal center-center" ]
                    [ div []
                        [ a [ class "google-sign-in btn", onClick OnFBSignIn ]
                            [ div [ class "left" ] [ img [ class "google-logo", src AppUrl.googleIconSvg ] [] ]
                            , text "Sign in with Google Account"
                            ]
                        ]
                    ]
                ]
            , div [ class "right-align" ]
                [ a [ class "btn btn-flat", onClick OnFBSkipSignIn ]
                    [ text "Skip" ]
                ]
            ]
        ]
