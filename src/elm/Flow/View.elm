module Flow.View exposing (..)

import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Html.Events.Extra exposing (onClickStopPropagation)
import Flow.Model as Model exposing (FlowAction, Model)
import List.Extra
import Toolkit.Operators exposing (..)
import Toolkit.Helpers exposing (..)
import Function exposing (..)
import Function.Infix exposing (..)
import FunctionalHelpers exposing (..)


flowDialogView : (FlowAction -> msg) -> Model msg -> Html msg
flowDialogView toClickMsg model =
    div []
        [ h1 []
            [ Model.getQuestion model |> text ]
        , div []
            (nextActionButtons toClickMsg model)
        ]


nextActionButtons : (FlowAction -> msg) -> Model msg -> List (Html msg)
nextActionButtons toClickMsg =
    Model.getNextActions
        >> List.map (createButton toClickMsg)


createButton toClickMsg na =
    case na of
        Model.YesNA ->
            button [ onClick (toClickMsg Model.YesAction) ] [ "Yes" |> text ]

        Model.NoNA ->
            button [ onClick (toClickMsg Model.NoAction) ] [ "No" |> text ]

        Model.BackNA ->
            button [ onClick (toClickMsg Model.BackAction) ] [ "Cancel" |> text ]

        Model.YesCustom msg ->
            button [ onClick msg ] [ "Yes" |> text ]



--nodeList : List ( Bool, Html msg ) -> List (Html msg)
--nodeList =
--    List.filter Tuple.first >> List.map Tuple.second
--
--
--showNoButton =
--    Model.isActionNode >> not
