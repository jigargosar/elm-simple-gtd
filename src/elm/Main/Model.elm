module Main.Model exposing (..)

import Json.Encode as E
import List.Extra as List
import Main.Msg exposing (..)
import Main.Types exposing (EditMode(EditNewTodoMode, EditTodoMode, NotEditing), Model, ModelF, defaultViewType)
import Maybe.Extra as Maybe
import Navigation exposing (Location)
import RandomIdGenerator as Random
import Random.Pcg as Random exposing (Seed)
import Time exposing (Time)
import Todo as Todo exposing (EncodedTodoList, TodoGroup, Todo, TodoId, TodoList)
import Toolkit.Operators exposing (..)
import Toolkit.Helpers exposing (..)
import Tuple2


type alias Model =
    Main.Types.Model


init : Time -> EncodedTodoList -> Model
init now encodedTodoList =
    Model now
        (Todo.decodeTodoList encodedTodoList)
        NotEditing
        defaultViewType
        (Random.seedFromTime now)


setViewState viewState m =
    { m | viewState = viewState }


getNow =
    .now


getViewState =
    (.viewState)


getTodoList : Model -> TodoList
getTodoList =
    (.todoList)


getGroupedTodoLists__ =
    getTodoList >> Todo.groupedTodoLists__


getGroupedTodoLists =
    getTodoList >> Todo.groupedTodoLists


getBinTodoList =
    getTodoList >> List.filter Todo.binFilter


getDoneTodoList =
    getTodoList >> List.filter Todo.doneFilter


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
