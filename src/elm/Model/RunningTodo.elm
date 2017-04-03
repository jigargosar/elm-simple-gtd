module Model.RunningTodo exposing (..)

import Maybe.Extra
import Model
import Model.Internal exposing (..)
import Model.TodoList
import RunningTodo exposing (RunningTodo)
import Time exposing (Time)
import Todo
import Todo.Types exposing (..)
import Toolkit.Helpers exposing (..)
import Toolkit.Operators exposing (..)
import FunctionExtra exposing (..)
import FunctionExtra.Operators exposing (..)
import Model.Types exposing (..)


getRunningTodoViewModel : Model -> Maybe RunningTodoViewModel
getRunningTodoViewModel m =
    let
        maybeTodo =
            getRunningTodoId m ?+> (Model.TodoList.findTodoById # m)
    in
        maybe2Tuple ( getMaybeRunningTodo m, maybeTodo )
            ?|> (toRunningTodoVM # m)


type alias RunningTodoViewModel =
    { todoVM : ViewModel, now : Time, elapsedTime : Time }


getRunningTodoId =
    getMaybeRunningTodo >> RunningTodo.getMaybeId


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


stopRunningTodo : ModelF
stopRunningTodo =
    setMaybeRunningTodo Nothing


startTodo id =
    updateMaybeRunningTodo (Model.getNow >> RunningTodo.start id)


shouldBeep : Model -> Bool
shouldBeep =
    apply2 ( getMaybeRunningTodo, Model.getNow >> Just )
        >> maybe2Tuple
        >>? RunningTodo.shouldBeepHelp
        >>?= False


setLastBeepedAt : Time -> ModelF
setLastBeepedAt now =
    updateMaybeRunningTodo
        (getMaybeRunningTodo
            ?>> RunningTodo.setLastBeepedAt now
        )
