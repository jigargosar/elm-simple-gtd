module Model.RunningTodo exposing (..)

import Maybe.Extra as Maybe
import Model
import Model.Internal as Model
import Model.TodoList
import RunningTodo exposing (RunningTodo)
import Time exposing (Time)
import Todo
import Todo.Types exposing (..)
import Toolkit.Helpers exposing (..)
import Toolkit.Operators exposing (..)
import Ext.Function exposing (..)
import Ext.Function.Infix exposing (..)
import Model.Types exposing (..)


getRunningTodoViewModel : Model -> Maybe RunningTodoViewModel
getRunningTodoViewModel m =
    let
        maybeTodo =
            getRunningTodoId m ?+> (Model.TodoList.findTodoById # m)
    in
        maybe2Tuple ( Model.getMaybeRunningTodo m, maybeTodo )
            ?|> (toRunningTodoVM # m)


type alias RunningTodoViewModel =
    { todoVM : ViewModel, now : Time, elapsedTime : Time }


getRunningTodoId =
    Model.getMaybeRunningTodo >> RunningTodo.getMaybeId


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
    Model.setMaybeRunningTodo Nothing


startTodo id =
    Model.updateMaybeRunningTodo (Model.getNow >> RunningTodo.start id)


shouldBeep : Model -> Bool
shouldBeep =
    apply2 ( Model.getNow >> Just, Model.getMaybeRunningTodo )
        >> maybe2Tuple
        >>? uncurry RunningTodo.shouldBeep
        >>?= False


setLastBeepedAt : Time -> ModelF
setLastBeepedAt now =
    Model.updateMaybeRunningTodo
        (Model.getMaybeRunningTodo
            ?>> RunningTodo.setLastBeepedAt now
        )
