module InboxFlow.View exposing (..)

import Flow
import InboxFlow
import Polymer.Attributes exposing (boolProperty)
import Toolkit.Helpers exposing (..)
import Toolkit.Operators exposing (..)
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import InboxFlow.Model as Model exposing (Model)
import Msg as Msg exposing (Msg)
import FunctionExtra exposing (..)
import Todo exposing (Todo)
import Function exposing ((>>>))
import Polymer.Paper exposing (iconButton, material)


type alias TodoViewModel =
    { text : String }


type alias ViewModel =
    { maybeTodo : Maybe TodoViewModel
    , question : String
    , flowActions : List ( String, Msg )
    }


toTodoViewModel todo =
    { text = Todo.getText todo }


toViewModel maybeTodo model =
    { maybeTodo = maybeTodo ?|> toTodoViewModel
    , question =
        Model.getQuestion model
        --    , flowActions = Model.getFlowActions Msg.OnInboxFlowAction model
    }



--inboxFlowView : Maybe Todo -> Model -> Html Msg
--inboxFlowView =
--    toViewModel >>> flowView
--


flowView : ViewModel -> Html Msg
flowView vm =
    material [ id "in-basket-flow-container" ]
        [ vm.maybeTodo ?|> processTodoView # vm ?= processingCompleteView
        ]


processingCompleteView =
    h1 [] [ text "Hurray! All stuff is processed ;)" ]


processTodoView : TodoViewModel -> ViewModel -> Html Msg
processTodoView todoVM vm =
    div []
        [ questionView vm
        , todoView todoVM
        , actionBar vm
        ]


todoView vm =
    h3 [] [ text vm.text ]


questionView vm =
    h1 [] [ vm.question |> text ]


actionBar : ViewModel -> Html Msg
actionBar vm =
    let
        buttonView ( buttonText, onClickMsg ) =
            Polymer.Paper.button
                [ boolProperty "raised" True
                , onClick onClickMsg
                ]
                [ text buttonText ]
    in
        div [] (vm.flowActions .|> buttonView)
