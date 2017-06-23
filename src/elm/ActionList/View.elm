module ActionList.View exposing (..)

import ActionList
import X.Keyboard exposing (onKeyDownStopPropagation)
import Model
import Toolkit.Helpers exposing (..)
import Toolkit.Operators exposing (..)
import X.Function exposing (..)
import X.Function.Infix exposing (..)
import List.Extra
import Maybe.Extra as Maybe
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import X.Html exposing (onClickStopPropagation)


init : Model.Model -> ActionList.Model -> Html Model.Msg
init appModel model =
    let
        searchText =
            model.searchText

        resList =
            [ "r1", "222", "r3", "r4", "r5" ]

        resultListView =
            resList .|> (\str -> div [] [ text str ])
    in
        div
            [ class "overlay"
            , onClick Model.OnDeactivateEditingMode
            ]
            [ div [ class "modal fixed-top-20p", onClickStopPropagation Model.NOOP, onKeyDownStopPropagation (\_ -> Model.NOOP) ]
                [ div [ class "modal-content" ]
                    [ div [ class "input-field" ]
                        [ input
                            [ autofocus True
                            , defaultValue searchText
                            ]
                            []
                        , label [ class "active" ] [ text "Enter action or option name" ]
                        ]
                    , div [] resultListView
                    ]
                ]
            ]
