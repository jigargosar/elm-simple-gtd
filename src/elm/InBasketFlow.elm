module InBasketFlow exposing (..)

import Flow
import Flow.Model
import Main.Msg exposing (Msg(OnFlowTrashItClicked))
import TodoCollection.Todo exposing (Todo)
import Toolkit.Operators exposing (..)
import Toolkit.Helpers exposing (..)


inBasketFlow =
    Flow.branch "Is it Actionable ?"
        (Flow.branch "Can be done under 2 mins?"
            (Flow.confirmAction "Do it now?"
                (Flow.action "Timer Started, Go Go Go !!!" OnFlowTrashItClicked)
            )
            (Flow.action "Involves Multiple Steps?" OnFlowTrashItClicked)
        )
        (Flow.branch "Is it worth keeping?"
            (Flow.branch "Could Require actionNode Later ?"
                (Flow.action "Move to SomDay/Maybe List?" OnFlowTrashItClicked)
                (Flow.action "Move to Reference?" OnFlowTrashItClicked)
            )
            (Flow.action "Trash it ?" OnFlowTrashItClicked)
        )
        |> Flow.init


type alias FlowModel =
    Flow.Model Msg


type alias ModelMapper =
    Model -> Model


type alias Model =
    { flow : FlowModel
    , todoList : List Todo
    }


modelConstructor todoList =
    Model inBasketFlow todoList


init todoList =
    modelConstructor todoList



-- .flow


getFlow : Model -> FlowModel
getFlow =
    (.flow)


setFlow : FlowModel -> ModelMapper
setFlow flow model =
    { model | flow = flow }


updateFlow : (Model -> FlowModel) -> ModelMapper
updateFlow updater model =
    setFlow (updater model) model


setMaybeFlow : Maybe FlowModel -> ModelMapper
setMaybeFlow maybeFlow model =
    maybeFlow ?|> setFlow # model ?= model


updateMaybeFlow : (Model -> Maybe FlowModel) -> ModelMapper
updateMaybeFlow maybeUpdater model =
    setMaybeFlow (maybeUpdater model) model


updateWithActionType : Flow.FlowActionType -> ModelMapper
updateWithActionType actionType =
    updateFlow (getFlow >> Flow.update actionType)



-- end .flow


mapFlow mapper =
    getFlow >> mapper
