module InBasketFlow.View exposing (..)

import Flow
import InBasketFlow
import Toolkit.Helpers exposing (..)
import Toolkit.Operators exposing (..)
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Html.Events.Extra exposing (onClickStopPropagation)
import InBasketFlow.Model as Model exposing (Model)
import Main.Msg as Msg exposing (Msg)
import FunctionalHelpers exposing (..)


type alias ViewModel =
    { question : String
    , flowActions : List ( String, Msg )
    }


view : Model -> Html Msg
view model =
    flowView model


flowView model =
    div []
        [ h1 [] [ Model.getQuestion model |> text ]
        , flowActionBar model
        ]


flowActionBar model =
    div [] (Model.getFlowActions Msg.OnInBasketFlowAction model .|> createNAB)


createNAB ( buttonText, onClickMsg ) =
    button [ onClick onClickMsg ] [ text buttonText ]
