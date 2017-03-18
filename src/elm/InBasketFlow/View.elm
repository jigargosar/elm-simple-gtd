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
import TodoStore.Todo


type alias TodoViewModel =
    { text : String }


type alias ViewModel =
    { maybeTodo : Maybe TodoViewModel
    , question : String
    , flowActions : List ( String, Msg )
    }


toTodoViewModel todo =
    { text = TodoStore.Todo.getText todo }


toViewModel model =
    { maybeTodo = Model.getCurrentTodo model ?|> toTodoViewModel
    , question = Model.getQuestion model
    , flowActions = Model.getFlowActions Msg.OnInBasketFlowAction model
    }


view : Model -> Html Msg
view =
    toViewModel >> flowView


flowView : ViewModel -> Html Msg
flowView vm =
    vm.maybeTodo ?|> processTodoView # vm ?= processingCompleteView


processingCompleteView =
    h1 [] [ text "Hurray! All stuff is processed ;)" ]


processTodoView : TodoViewModel -> ViewModel -> Html Msg
processTodoView todoVM vm =
    div []
        [ questionView vm
        , actionBar vm
        ]


questionView vm =
    h1 [] [ vm.question |> text ]


actionBar : ViewModel -> Html Msg
actionBar vm =
    let
        buttonView ( buttonText, onClickMsg ) =
            button [ onClick onClickMsg ] [ text buttonText ]
    in
        div [] (vm.flowActions .|> buttonView)
