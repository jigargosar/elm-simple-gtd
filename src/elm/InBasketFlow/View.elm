module InBasketFlow.View exposing (..)

import Flow.Model as FlowModel__
import Toolkit.Helpers exposing (..)
import Toolkit.Operators exposing (..)
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Html.Events.Extra exposing (onClickStopPropagation)
import InBasketFlow.Model as Model
import Main.Msg as Msg


view model =
    Model.mapFlow flowView


flowView flowModel =
    div []
        [ h1 []
            [ FlowModel__.getQuestion flowModel |> text ]
        , div []
            (nextActionButtons flowModel)
        ]


nextActionButtons flowModel =
    flowModel |> FlowModel__.getNextActions__ Msg.OnInBasketFlowAction .|> createNAB


createNAB ( buttonText, onClickMsg ) =
    button [ onClick onClickMsg ] [ text buttonText ]
