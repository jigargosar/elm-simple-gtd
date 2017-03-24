module Main.Model exposing (..)

import Json.Encode as E
import List.Extra as List
import Main.Msg exposing (..)
import Maybe.Extra as Maybe
import Navigation exposing (Location)
import RandomIdGenerator as Random
import Random.Pcg as Random exposing (Seed)
import Time exposing (Time)
import Todo as Todo exposing (EncodedTodoList, TodoGroup, Todo, TodoId, TodoList)
import TodoGroupViewModel exposing (getTodoGroupsViewModel)
import Toolkit.Operators exposing (..)
import Toolkit.Helpers exposing (..)
import Tuple2
import ViewState exposing (ViewState, defaultViewState)


--type ViewState
--    = AllTodoListsViewState
--
--
--defaultViewState =
--    AllTodoListsViewState


type EditMode
    = EditNewTodoMode String
    | EditTodoMode Todo
    | NotEditing


type alias Model =
    { now : Time
    , todoList : TodoList
    , editMode : EditMode
    , viewState : ViewState
    , seed : Seed
    }


type alias ModelMapper =
    Model -> Model


init : Time -> EncodedTodoList -> Model
init now encodedTodoList =
    Model now
        (Todo.decodeTodoList encodedTodoList)
        NotEditing
        defaultViewState
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


getTodoGroupsViewModel =
    getTodoList >> TodoGroupViewModel.getTodoGroupsViewModel


getBinTodoList =
    getTodoList >> List.filter Todo.binFilter


getFirstInboxTodo =
    getTodoList >> Todo.getFirstInboxTodo


showTodoList =
    setViewState ViewState.AllGrouped


mapAllExceptDeleted mapper =
    getTodoList >> Todo.mapAllExceptDeleted mapper


setEditModeTo : EditMode -> ModelMapper
setEditModeTo editMode m =
    { m | editMode = editMode }


getEditMode : Model -> EditMode
getEditMode =
    (.editMode)


activateEditNewTodoMode : String -> ModelMapper
activateEditNewTodoMode text =
    setEditModeTo (EditNewTodoMode text)


activateEditTodoMode : Todo -> ModelMapper
activateEditTodoMode todo =
    setEditModeTo (EditTodoMode todo)


updateEditTodoText : String -> ModelMapper
updateEditTodoText text m =
    case getEditMode m of
        EditTodoMode todo ->
            setEditModeTo (EditTodoMode (Todo.setText text todo)) m

        _ ->
            m


getSeed : Model -> Seed
getSeed =
    (.seed)


setSeed : Seed -> ModelMapper
setSeed seed model =
    { model | seed = seed }


updateSeed : (Model -> Seed) -> ModelMapper
updateSeed updater model =
    setSeed (updater model) model


deactivateEditingMode =
    setEditModeTo NotEditing


findTodoEqualById todo =
    getTodoList >> List.find (Todo.equalById todo)
