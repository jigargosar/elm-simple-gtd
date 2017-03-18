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


toViewModel model =
    { question = Model.getQuestion model
    , flowActions = Model.getFlowActions Msg.OnInBasketFlowAction model
    }


view : Model -> Html Msg
view =
    toViewModel >> flowView


flowView : ViewModel -> Html Msg
flowView vm =
    div []
        [ h1 [] [ vm.question |> text ]
        , flowActionBar vm
        ]


flowActionBar vm =
    let
        buttonView ( buttonText, onClickMsg ) =
            button [ onClick onClickMsg ] [ text buttonText ]
    in
        div [] (vm.flowActions .|> buttonView)
