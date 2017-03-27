module Model.RunningTodo exposing (..)

import Maybe.Extra
import Model
import Model.TodoList
import RunningTodoDetails exposing (RunningTodoDetails)
import Time exposing (Time)
import Todo exposing (Todo)
import Toolkit.Helpers exposing (..)
import Toolkit.Operators exposing (..)
import FunctionExtra exposing (..)
import Types exposing (Model, ModelF)


getRunningTodoViewModel : Model -> Maybe RunningTodoViewModel
getRunningTodoViewModel m =
    let
        maybeTodo =
            getRunningTodoId m ?+> (Model.TodoList.getTodoById # m)
    in
        maybe2Tuple ( getRunningTodoDetails m, maybeTodo )
            ?|> (toRunningTodoDetailsVM # m)


type alias RunningTodoViewModel =
    { todoVM : Todo.ViewModel, now : Time, elapsedTime : Time }


getRunningTodoDetails : Model -> Maybe RunningTodoDetails
getRunningTodoDetails =
    (.runningTodoDetails)


getRunningTodoId =
    getRunningTodoDetails >> RunningTodoDetails.getMaybeId


toRunningTodoDetailsVM : ( RunningTodoDetails, Todo ) -> Model -> RunningTodoViewModel
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
            lastBeepedAt - now > 15 * Time.second

        _ ->
            False


updateLastBeepedTo : Time -> ModelF
updateLastBeepedTo now =
    updateMaybeRunningTodoDetails
        (apply2 ( getRunningTodoDetails, Just )
            >> maybe2Tuple
            >> Maybe.map
                (\( d, m ) ->
                    case d.state of
                        RunningTodoDetails.Running runningDetails ->
                            d

                        _ ->
                            d
                )
        )
