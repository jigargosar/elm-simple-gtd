module Model.RunningTodo exposing (..)

import Maybe.Extra as Maybe
import Model
import Model.Internal as Model
import Model.TodoStore
import RunningTodo exposing (RunningTodo)
import Time exposing (Time)
import Todo
import Toolkit.Helpers exposing (..)
import Toolkit.Operators exposing (..)
import Ext.Function exposing (..)
import Ext.Function.Infix exposing (..)
import Model.Types exposing (..)


getRunningTodoViewModel : Model -> Maybe RunningTodoViewModel
getRunningTodoViewModel m =
    let
        maybeTodo =
            getMaybeRunningTodo m
    in
        maybe2Tuple ( Model.getMaybeRunningTodoInfo m, maybeTodo )
            ?|> (toRunningTodoVM # m)


getMaybeRunningTodo m =
    getRunningTodoId m ?+> (Model.TodoStore.findTodoById # m)


type alias RunningTodoViewModel =
    { todoVM : Todo.ViewModel, now : Time, elapsedTime : Time }


getRunningTodoId =
    Model.getMaybeRunningTodoInfo >>? RunningTodo.getId


toRunningTodoVM : ( RunningTodo, Todo.Model ) -> Model -> RunningTodoViewModel
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


startTodo todo =
    Model.updateMaybeRunningTodo (Model.getNow >> RunningTodo.start todo)


shouldBeep : Model -> Bool
shouldBeep =
    apply2 ( Model.getNow >> Just, Model.getMaybeRunningTodoInfo )
        >> maybe2Tuple
        >>? uncurry RunningTodo.shouldBeep
        >>?= False


setLastBeepedAt : Time -> ModelF
setLastBeepedAt now =
    Model.updateMaybeRunningTodo
        (Model.getMaybeRunningTodoInfo
            ?>> RunningTodo.setLastBeepedAt now
        )
