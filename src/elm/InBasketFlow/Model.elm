module InBasketFlow.Model exposing (..)

import Toolkit.Helpers exposing (..)
import Toolkit.Operators exposing (..)
import Flow
import Main.Msg as Msg exposing (Msg)
import Todo exposing (Todo, TodoList)


inBasketFlow =
    Flow.branch "Is it Actionable ?"
        (Flow.branch "Can be done under 2 mins?"
            (Flow.action "Batch it in Under 2 minutes?" Msg.MoveToUnder2mList)
            (Flow.branch "Involves Multiple Steps?"
                (Flow.action "Move To Projects?" Msg.MoveToUnder2mList)
                (Flow.branch "Am I the right Person to do this?"
                    (Flow.branch "Should it be done at specific time?"
                        (Flow.action "Move To Calender?" Msg.MoveToUnder2mList)
                        (Flow.action "Move To Next Actions?" Msg.MoveToUnder2mList)
                    )
                    (Flow.action "Move To Waiting For?" Msg.MoveToUnder2mList)
                )
            )
        )
        (Flow.branch "Is it worth keeping?"
            (Flow.branch "Could Require actionNode Later ?"
                (Flow.action "Move to SomDay/Maybe List?" Msg.OnFlowTrashItClicked)
                (Flow.action "Move to Reference?" Msg.OnFlowTrashItClicked)
            )
            (Flow.action "Trash it ?" Msg.MarkDeleted)
        )
        |> Flow.init


type alias FlowModel =
    Flow.Model Msg


type alias ModelMapper =
    Model -> Model


type alias Model =
    { flow : FlowModel
    , todoList : TodoList
    }


modelConstructor todoList =
    Model inBasketFlow todoList



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


getTodoList : Model -> TodoList
getTodoList =
    (.todoList)


setTodoList : TodoList -> ModelMapper
setTodoList todoList model =
    { model | todoList = todoList }


updateTodoList : (Model -> TodoList) -> ModelMapper
updateTodoList updater model =
    setTodoList (updater model) model



-- end .flow


mapFlow mapper =
    getFlow >> mapper


getQuestion =
    getFlow >> Flow.getQuestion


getFlowActions flowActionToMsg =
    getFlow >> Flow.getNextActions flowActionToMsg


getCurrentTodo =
    getTodoList >> List.head
