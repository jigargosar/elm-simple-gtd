module Model exposing (..)

import RunningTodoDetails exposing (RunningTodoDetails)
import Dict
import InboxFlow.View exposing (TodoViewModel)
import Json.Encode as E
import List.Extra as List
import Types exposing (Model, ModelF, MainViewType(..), defaultViewType)
import Maybe.Extra as Maybe
import Navigation exposing (Location)
import RandomIdGenerator as Random
import Random.Pcg as Random exposing (Seed)
import Time exposing (Time)
import Todo as Todo exposing (EncodedTodoList, TodoGroup, Todo, TodoId, TodoList)
import Toolkit.Operators exposing (..)
import Toolkit.Helpers exposing (..)
import Tuple2


type alias RunningTodoViewModel =
    { todoVM : Todo.ViewModel, now : Time, elapsedTime : Time }


getRunningTodoDetails : Model -> Maybe RunningTodoDetails
getRunningTodoDetails =
    (.runningTodoDetails)


getRunningTodoId =
    getRunningTodoDetails >> RunningTodoDetails.getMaybeId


getRunningTodoViewModel : Model -> Maybe RunningTodoViewModel
getRunningTodoViewModel m =
    let
        maybeTodo =
            getRunningTodoId m ?+> (getTodoById # m)
    in
        maybe2Tuple ( getRunningTodoDetails m, maybeTodo )
            ?|> (toRunningTodoDetailsVM # m)


toRunningTodoDetailsVM : ( RunningTodoDetails, Todo ) -> Model -> RunningTodoViewModel
toRunningTodoDetailsVM ( runningTodoDetails, todo ) m =
    let
        now =
            getNow m
    in
        { todoVM = Todo.toVM todo
        , now = now
        , elapsedTime = RunningTodoDetails.getElapsedTime now runningTodoDetails
        }


getTodoById : TodoId -> Model -> Maybe Todo
getTodoById id =
    getTodoList >> Todo.findById id


getMainViewType : Model -> MainViewType
getMainViewType =
    (.mainViewType)


setMainViewType : MainViewType -> ModelF
setMainViewType mainViewType model =
    { model | mainViewType = mainViewType }


updateMainViewType : (Model -> MainViewType) -> ModelF
updateMainViewType updater model =
    setMainViewType (updater model) model


getNow : Model -> Time
getNow =
    (.now)


setNow : Time -> ModelF
setNow now model =
    { model | now = now }


updateNow : (Model -> Time) -> ModelF
updateNow updater model =
    setNow (updater model) model


getTodoList : Model -> TodoList
getTodoList =
    (.todoList)


getFilteredTodoList =
    apply2 ( getCurrentTodoListFilter, getTodoList )
        >> uncurry List.filter
        >> List.sortBy (Todo.getModifiedAt >> negate)


getCurrentTodoListFilter model =
    case getMainViewType model of
        BinView ->
            Todo.binFilter

        DoneView ->
            Todo.doneFilter

        _ ->
            always (True)


getFirstInboxTodo =
    getTodoList >> Todo.getFirstInboxTodo


mapAllExceptDeleted mapper =
    getTodoList >> Todo.mapAllExceptDeleted mapper


getSeed : Model -> Seed
getSeed =
    (.seed)


setSeed : Seed -> ModelF
setSeed seed model =
    { model | seed = seed }


findTodoEqualById todo =
    getTodoList >> List.find (Todo.equalById todo)
