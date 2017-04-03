module Model.RunningTodo exposing (..)

import Maybe.Extra
import Model
import Model.TodoList
import RunningTodo exposing (RunningTodo)
import Time exposing (Time)
import Todo
import Todo.Types exposing (..)
import Toolkit.Helpers exposing (..)
import Toolkit.Operators exposing (..)
import FunctionExtra exposing (..)
import Model.Types exposing (..)


getRunningTodoViewModel : Model -> Maybe RunningTodoViewModel
getRunningTodoViewModel m =
    let
        maybeTodo =
            getRunningTodoId m ?+> (Model.TodoList.findTodoById # m)
    in
        maybe2Tuple ( getRunningTodo m, maybeTodo )
            ?|> (toRunningTodoVM # m)


type alias RunningTodoViewModel =
    { todoVM : ViewModel, now : Time, elapsedTime : Time }


getRunningTodo : Model -> Maybe RunningTodo
getRunningTodo =
    (.runningTodo)


getRunningTodoId =
    getRunningTodo >> RunningTodo.getMaybeId


toRunningTodoVM : ( RunningTodo, Todo ) -> Model -> RunningTodoViewModel
toRunningTodoVM ( runningTodo, todo ) m =
    let
        now =
            Model.getNow m
    in
        { todoVM = Todo.toVM todo
        , now = now
        , elapsedTime = RunningTodo.getElapsedTime now runningTodo
        }


setRunningTodo : Maybe RunningTodo -> ModelF
setRunningTodo runningTodo model =
    { model | runningTodo = runningTodo }


updateMaybeRunningTodo : (Model -> Maybe RunningTodo) -> ModelF
updateMaybeRunningTodo updater model =
    setRunningTodo (updater model) model


stopRunningTodo : ModelF
stopRunningTodo =
    setRunningTodo RunningTodo.init


startTodo id =
    updateMaybeRunningTodo (Model.getNow >> RunningTodo.start id)


shouldBeep =
    apply2 ( getRunningTodo, Model.getNow >> Just )
        >> maybe2Tuple
        >> Maybe.Extra.unwrap False shouldBeepHelp


shouldBeepHelp ( details, now ) =
    case details.state of
        RunningTodo.Running { lastBeepedAt } ->
            now - lastBeepedAt > 10 * Time.minute

        _ ->
            False


updateLastBeepedTo : Time -> ModelF
updateLastBeepedTo now =
    updateMaybeRunningTodo
        (getRunningTodo
            >> Maybe.map
                (\d ->
                    case d.state of
                        RunningTodo.Running runningState ->
                            { d
                                | state =
                                    RunningTodo.Running { runningState | lastBeepedAt = now }
                            }

                        _ ->
                            d
                )
        )
