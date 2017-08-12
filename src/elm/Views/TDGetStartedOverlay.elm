module View.GetStarted exposing (..)

import AppUrl
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import X.Html exposing (onClickStopPropagation)
import X.Keyboard


setup config form =
    let
        updateSetupFormTodoText =
            config.onSetTodoFormText form
    in
    div
        [ class "overlay"
        , onClickStopPropagation config.noop
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
                            , X.Keyboard.onEnterKeyPress config.onSaveExclusiveModeForm
                            , onInput updateSetupFormTodoText
                            ]
                            []
                        , label [ class "active" ] [ text "Todo" ]
                        ]
                    ]
                , div [ class "right-align" ]
                    [ button [ class "btn", onClick config.onSaveExclusiveModeForm ]
                        [ text "Ok" ]
                    ]
                ]
            ]
        ]
