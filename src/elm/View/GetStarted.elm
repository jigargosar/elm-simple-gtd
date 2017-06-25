module View.GetStarted exposing (..)

import AppUrl
import Model
import Toolkit.Helpers exposing (..)
import Toolkit.Operators exposing (..)
import X.Function exposing (..)
import X.Function.Infix exposing (..)
import List.Extra as List
import Maybe.Extra as Maybe
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import X.Html exposing (onClickStopPropagation)


signInOverlay =
    div
        [ class "overlay"
        , onClickStopPropagation Model.noop
        ]
        [ div [ class "modal fixed-center" ]
            [ div [ class "modal-content" ]
                [ h5 [ class "" ]
                    [ text "One click sign in" ]
                , div [ class "section layout horizontal center-center" ]
                    [ div []
                        [ a [ class "google-sign-up btn", onClick Model.OnSignIn ]
                            [ div [ class "left" ] [ img [ class "google-logo", src AppUrl.googleIconSvg ] [] ]
                            , text "Sign in with Google Account"
                            ]
                        ]
                    ]
                ]
            , div [ class "right-align" ]
                [ a [ class "btn btn-flat", onClick Model.OnSkipSignIn ]
                    [ text "Skip" ]
                ]
            ]
        ]


setupOverlay =
    div
        [ class "overlay"
        , onClickStopPropagation Model.noop
        ]
        [ div [ class "modal fixed-center" ]
            [ div [ class "modal-content" ]
                [ h5 []
                    [ text "Name one thing that you would like to get done today" ]
                , div [ class "section" ]
                    [ div [ class "input-field" ]
                        [ input [ autofocus True, placeholder "E.g. Get Milk, Check Email" ] []
                        , label [ class "active" ] [ text "Task" ]
                        ]
                    ]
                , div [ class "right-align" ]
                    [ button [ class "btn", onClick Model.OnDeactivateEditingMode ]
                        [ text "Ok" ]
                    ]
                ]
            ]
        ]
