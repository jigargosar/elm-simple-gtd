module Main.Model exposing (..)

import Json.Encode as E
import Main.Msg exposing (Msg)
import Maybe.Extra as Maybe
import Navigation exposing (Location)
import PouchDB
import RandomIdGenerator as Random
import Return exposing (Return)
import TodoCollection exposing (EditMode(..), TodosModel)
import Random.Pcg as Random exposing (Seed)
import Time exposing (Time)
import TodoCollection.Todo as Todo exposing (EncodedTodoList, Todo, TodoId)
import Toolkit.Operators exposing (..)
import Toolkit.Helpers exposing (..)
import Tuple2


type alias Flags =
    { now : Time, encodedTodoList : EncodedTodoList }


type alias Model =
    { todosModel : TodosModel
    , editMode : EditMode
    }


modelConstructor editMode todosModel =
    Model todosModel editMode


type alias ReturnMapper =
    Return Msg Model -> Return Msg Model


type alias ModelMapper =
    Model -> Model


initWithFlagsAndLocation : Flags -> Location -> Model
initWithFlagsAndLocation { now, encodedTodoList } location =
    let
        generateTodoModel =
            Todo.decodeTodoList
                >> TodoCollection.todoModelGenerator
                >> Random.step

        todoModelFromSeed =
            Random.seedFromTime >> generateTodoModel encodedTodoList >> Tuple.first
    in
        now
            |> todoModelFromSeed
            >> (modelConstructor NotEditing)


getTodosModel : Model -> TodosModel
getTodosModel =
    (.todosModel)


setEditModeTo : EditMode -> ReturnMapper
setEditModeTo editMode =
    Return.map (\m -> { m | editMode = editMode })


setEditModeTo2 : EditMode -> ModelMapper
setEditModeTo2 editMode m =
    { m | editMode = editMode }


getEditMode : Model -> EditMode
getEditMode =
    (.editMode)


activateAddNewTodoMode : String -> ModelMapper
activateAddNewTodoMode text =
    setEditModeTo2 (EditNewTodoMode text)


activateEditTodoMode : Todo -> ModelMapper
activateEditTodoMode todo =
    setEditModeTo2 (EditTodoMode todo)


updateEditTodoText : String -> ModelMapper
updateEditTodoText text m =
    case getEditMode m of
        EditTodoMode todo ->
            setEditModeTo2 (EditTodoMode (Todo.setText text todo)) m

        _ ->
            m


setTodosModel : TodosModel -> ModelMapper
setTodosModel todosModel m =
    { m | todosModel = todosModel }


updateTodosModel : (Model -> TodosModel) -> ModelMapper
updateTodosModel fun model =
    setTodosModel (fun model) model


addNewTodoAndDeactivateAddNewTodoMode : Model -> ( Model, Maybe Todo )
addNewTodoAndDeactivateAddNewTodoMode =
    addNewTodo
        >> Tuple2.mapFirst (setEditModeTo2 NotEditing)


addNewTodoAndContinueAdding : Model -> ( Model, Maybe Todo )
addNewTodoAndContinueAdding =
    addNewTodo
        >> Tuple2.mapFirst (activateAddNewTodoMode "")


addNewTodo : Model -> ( Model, Maybe Todo )
addNewTodo m =
    case getEditMode m of
        EditNewTodoMode text ->
            if String.trim text |> String.isEmpty then
                ( m, Nothing )
            else
                TodoCollection.addNewTodo text m.todosModel
                    |> Tuple2.mapEach (setTodosModel # m) (Just)

        _ ->
            ( m, Nothing )


deleteTodo todoId m =
    TodoCollection.deleteTodo todoId m.todosModel
        |> Tuple2.mapFirst (setTodosModel # m)


saveEditingTodoAndDeactivateEditTodoMode : Model -> ( Model, Maybe Todo )
saveEditingTodoAndDeactivateEditTodoMode =
    saveEditingTodo
        >> Tuple2.mapFirst (setEditModeTo2 NotEditing)


saveEditingTodo : Model -> ( Model, Maybe Todo )
saveEditingTodo m =
    case getEditMode m of
        EditTodoMode todo ->
            if Todo.isTextEmpty todo then
                ( m, Nothing )
            else
                TodoCollection.replaceTodoIfIdMatches todo m.todosModel
                    |> Tuple2.mapEach (setTodosModel # m) (Just)

        _ ->
            ( m, Nothing )


setTodosModelFromTuple =
    Return.map (\( todosModel, m ) -> { m | todosModel = todosModel })


persistTodoCmd todo =
    PouchDB.pouchDBBulkDocsHelp "todo-db" (Todo.encodeSingleton todo)
