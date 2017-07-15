module View.GetStarted exposing (..)

import AppUrl
import Firebase.Types exposing (FirebaseMsg(OnFBNOOP, OnFBSignIn, OnFBSkipSignIn))
import Model
import Msg
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import TodoMsg
import X.Html exposing (onClickStopPropagation)
import X.Keyboard
import XMMsg


signInOverlay =
    div
        [ class "overlay"
        , onClickStopPropagation OnFBNOOP
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
        |> Html.map Msg.OnFirebaseMsg


setup form =
    let
        addTodoMsg =
            XMMsg.onSaveExclusiveModeForm

        updateSetupFormTodoText =
            TodoMsg.onSetTodoFormText form
    in
        div
            [ class "overlay"
            , onClickStopPropagation Model.noop
            ]
            [ div [ class "modal fixed-center" ]
                [ div [ class "modal-content" ]
                    [ h5 [ class "flow-text" ]
                        [ text "Enter one thing that you would like to get done Today" ]
                    , div [ class "section" ]
                        [ div [ class "input-field" ]
                            [ input
                                [ autofocus True
                                , placeholder "E.g. Get Milk, Check Email"
                                , X.Keyboard.onEnter addTodoMsg
                                , onInput updateSetupFormTodoText
                                ]
                                []
                            , label [ class "active" ] [ text "Todo" ]
                            ]
                        ]
                    , div [ class "right-align" ]
                        [ button [ class "btn", onClick addTodoMsg ]
                            [ text "Ok" ]
                        ]
                    ]
                ]
            ]
