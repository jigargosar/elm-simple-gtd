module Main.Model exposing (..)

import ActiveTask exposing (MaybeTask)
import Dict
import InboxFlow.View exposing (TodoViewModel)
import Json.Encode as E
import List.Extra as List
import Main.Msg exposing (..)
import Main.Types exposing (EditMode(EditNewTodoMode, EditTodoMode, NotEditing), Model, ModelF, MainViewType(..), defaultViewType)
import Maybe.Extra as Maybe
import Navigation exposing (Location)
import RandomIdGenerator as Random
import Random.Pcg as Random exposing (Seed)
import Time exposing (Time)
import Todo as Todo exposing (EncodedTodoList, TodoGroup, Todo, TodoId, TodoList)
import Toolkit.Operators exposing (..)
import Toolkit.Helpers exposing (..)
import Tuple2


{-|
    for external files
-}
type alias Model =
    Main.Types.Model


init : Time -> EncodedTodoList -> Model
init now encodedTodoList =
    Model now
        (Todo.decodeTodoList encodedTodoList)
        NotEditing
        defaultViewType
        (Random.seedFromTime now)
        ActiveTask.init


type alias ActiveTaskViewModel =
    { task : ActiveTask.Task, todoVM : Todo.ViewModel, now : Time, elapsedTime : Time }


getActiveTaskViewModel : Model -> Maybe ActiveTaskViewModel
getActiveTaskViewModel m =
    let
        maybeTodo =
            m.activeTask ?|> ActiveTask.getTodoId ?+> (getTodoById # m)
    in
        maybe2Tuple
            ( m.activeTask
            , maybeTodo ?|> Todo.toVM
            )
            ?|> (toActiveTaskVM # m)


toActiveTaskVM ( task, todoVM ) m =
    let
        now =
            getNow m
    in
        { task = task, todoVM = todoVM, now = now, elapsedTime = ActiveTask.getElapsedTime now task }


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


setEditModeTo : EditMode -> ModelF
setEditModeTo editMode m =
    { m | editMode = editMode }


getEditMode : Model -> EditMode
getEditMode =
    (.editMode)


activateEditNewTodoMode : String -> ModelF
activateEditNewTodoMode text =
    setEditModeTo (EditNewTodoMode text)


activateEditTodoMode : Todo -> ModelF
activateEditTodoMode todo =
    setEditModeTo (EditTodoMode todo)


updateEditTodoText : String -> ModelF
updateEditTodoText text m =
    case getEditMode m of
        EditTodoMode todo ->
            setEditModeTo (EditTodoMode (Todo.setText text todo)) m

        _ ->
            m


getSeed : Model -> Seed
getSeed =
    (.seed)


setSeed : Seed -> ModelF
setSeed seed model =
    { model | seed = seed }


updateSeed : (Model -> Seed) -> ModelF
updateSeed updater model =
    setSeed (updater model) model


deactivateEditingMode =
    setEditModeTo NotEditing


findTodoEqualById todo =
    getTodoList >> List.find (Todo.equalById todo)
