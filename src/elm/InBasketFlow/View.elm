module InBasketFlow.View exposing (..)

import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Html.Events.Extra exposing (onClickStopPropagation)
import InBasketFlow.Model as Model exposing (InBasketFlowActionType, Model)
import List.Extra
import Toolkit.Operators exposing (..)
import Toolkit.Helpers exposing (..)
import Function exposing (..)
import Function.Infix exposing (..)
import FunctionalHelpers exposing (..)


flowDialogView : (InBasketFlowActionType -> msg) -> Model msg -> Html msg
flowDialogView toClickMsg model =
    div []
        [ h1 []
            [ Model.getQuestion model |> text ]
        , div []
            (nextActionButtons toClickMsg model)
        ]


nextActionButtons : (InBasketFlowActionType -> msg) -> Model msg -> List (Html msg)
nextActionButtons toClickMsg =
    Model.getNextActions
        >> List.map (createButton toClickMsg)


createButton toClickMsg na =
    case na of
        Model.YesNA ->
            button [ onClick (toClickMsg Model.Yes) ] [ "Yes" |> text ]

        Model.NoNa ->
            button [ onClick (toClickMsg Model.No) ] [ "No" |> text ]

        Model.BackNa ->
            button [ onClick (toClickMsg Model.Back) ] [ "Back" |> text ]

        Model.YesCustom msg ->
            button [ onClick msg ] [ "Yes" |> text ]



--nodeList : List ( Bool, Html msg ) -> List (Html msg)
--nodeList =
--    List.filter Tuple.first >> List.map Tuple.second
--
--
--showNoButton =
--    Model.isActionNode >> not
