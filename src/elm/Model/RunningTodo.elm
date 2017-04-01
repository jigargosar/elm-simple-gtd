module Model.RunningTodo exposing (..)

import Maybe.Extra
import Model
import Model.TodoList
import RunningTodoDetails exposing (RunningTodoDetails)
import Time exposing (Time)
import Todo
import TodoModel.Types exposing (..)
import Toolkit.Helpers exposing (..)
import Toolkit.Operators exposing (..)
import FunctionExtra exposing (..)
import Model.Types exposing (..)


getRunningTodoViewModel : Model -> Maybe RunningTodoViewModel
getRunningTodoViewModel m =
    let
        maybeTodo =
            getRunningTodoId m ?+> (Model.TodoList.getTodoById # m)
    in
        maybe2Tuple ( getRunningTodoDetails m, maybeTodo )
            ?|> (toRunningTodoDetailsVM # m)


type alias RunningTodoViewModel =
    { todoVM : ViewModel, now : Time, elapsedTime : Time }


getRunningTodoDetails : Model -> Maybe RunningTodoDetails
getRunningTodoDetails =
    (.runningTodoDetails)


getRunningTodoId =
    getRunningTodoDetails >> RunningTodoDetails.getMaybeId


toRunningTodoDetailsVM : ( RunningTodoDetails, TodoModel ) -> Model -> RunningTodoViewModel
toRunningTodoDetailsVM ( runningTodoDetails, todo ) m =
    let
        now =
            Model.getNow m
    in
        { todoVM = Todo.toVM todo
        , now = now
        , elapsedTime = RunningTodoDetails.getElapsedTime now runningTodoDetails
        }


setRunningTodoDetails : Maybe RunningTodoDetails -> ModelF
setRunningTodoDetails runningTodoDetails model =
    { model | runningTodoDetails = runningTodoDetails }


updateMaybeRunningTodoDetails : (Model -> Maybe RunningTodoDetails) -> ModelF
updateMaybeRunningTodoDetails updater model =
    setRunningTodoDetails (updater model) model


stopRunningTodo : ModelF
stopRunningTodo =
    setRunningTodoDetails RunningTodoDetails.init


startTodo id =
    updateMaybeRunningTodoDetails (Model.getNow >> RunningTodoDetails.start id)


shouldBeep =
    apply2 ( getRunningTodoDetails, Model.getNow >> Just )
        >> maybe2Tuple
        >> Maybe.Extra.unwrap False shouldBeepHelp


shouldBeepHelp ( details, now ) =
    case details.state of
        RunningTodoDetails.Running { lastBeepedAt } ->
            now - lastBeepedAt > 10 * Time.minute

        _ ->
            False


updateLastBeepedTo : Time -> ModelF
updateLastBeepedTo now =
    updateMaybeRunningTodoDetails
        (getRunningTodoDetails
            >> Maybe.map
                (\d ->
                    case d.state of
                        RunningTodoDetails.Running runningState ->
                            { d
                                | state =
                                    RunningTodoDetails.Running { runningState | lastBeepedAt = now }
                            }

                        _ ->
                            d
                )
        )
