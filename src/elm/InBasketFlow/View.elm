module InBasketFlow.View exposing (..)

import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Html.Events.Extra exposing (onClickStopPropagation)
import InBasketFlow.Model as Model exposing (Model)


type InBasketFlowActionType
    = Yes
    | No
    | Back


flowDialogView : (InBasketFlowActionType -> msg) -> Model msg -> Html msg
flowDialogView toClickMsg model =
    div []
        [ h1 []
            [ Model.getQuestion model |> text ]
        , div []
            [ button [ onClick (toClickMsg Yes) ] [ "Yes" |> text ]
            , button [ onClick (toClickMsg No) ] [ "No" |> text ]
            , button [ onClick (toClickMsg Back) ] [ "Back" |> text ]
            ]
        ]
