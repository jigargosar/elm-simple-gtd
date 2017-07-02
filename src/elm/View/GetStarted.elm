module View.GetStarted exposing (..)

import AppUrl
import Firebase
import Model
import Todo.Msg
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import X.Html exposing (onClickStopPropagation)
import X.Keyboard


signInOverlay =
    div
        [ class "overlay"
        , onClickStopPropagation Firebase.NOOP
        ]
        [ div [ class "modal fixed-center" ]
            [ div [ class "modal-content" ]
                [ h5 [ class "" ]
                    [ text "One click sign in" ]
                , div [ class "section layout horizontal center-center" ]
                    [ div []
                        [ a [ class "google-sign-in btn", onClick Firebase.OnSignIn ]
                            [ div [ class "left" ] [ img [ class "google-logo", src AppUrl.googleIconSvg ] [] ]
                            , text "Sign in with Google Account"
                            ]
                        ]
                    ]
                ]
            , div [ class "right-align" ]
                [ a [ class "btn btn-flat", onClick Firebase.OnSkipSignIn ]
                    [ text "Skip" ]
                ]
            ]
        ]
        |> Html.map Model.OnFirebaseMsg


setup form =
    let
        addTodoMsg =
            Model.OnSaveCurrentForm

        updateSetupFormTodoText =
            Todo.Msg.UpdateSetupFormTodoText form >> Model.OnTodoMsg
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
