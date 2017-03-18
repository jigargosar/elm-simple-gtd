module InBasketFlow.View exposing (..)

import Toolkit.Helpers exposing (..)
import Toolkit.Operators exposing (..)
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Html.Events.Extra exposing (onClickStopPropagation)


view model =
    div []
            [ h1 []
                [ Model.getQuestion model |> text ]
--            , div []
--                (nextActionButtons toClickMsg model)
            ]
