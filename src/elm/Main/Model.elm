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


updateEditTodoText : String -> ReturnMapper
updateEditTodoText text =
    Return.map (\m -> ( getEditMode m, Return.singleton m ))
        >> Return.andThen (uncurry (updateEditTodoTextHelp text))


updateEditTodoTextHelp : String -> EditMode -> ReturnMapper
updateEditTodoTextHelp text editMode =
    case editMode of
        EditTodoMode todo ->
            setEditModeTo (EditTodoMode (Todo.setText text todo))

        _ ->
            identity


setTodosModel : TodosModel -> ModelMapper
setTodosModel todosModel m =
    { m | todosModel = todosModel }


updateTodosModel : (Model -> TodosModel) -> ModelMapper
updateTodosModel fun model =
    setTodosModel (fun model) model


updateTodosModelTuple2 : (Model -> ( TodosModel, x )) -> Model -> ( Model, x )
updateTodosModelTuple2 fun model =
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


saveEditingTodoAndDeactivateEditTodoMode : ReturnMapper
saveEditingTodoAndDeactivateEditTodoMode =
    saveEditingTodo
        >> setEditModeTo NotEditing


saveEditingTodo : ReturnMapper
saveEditingTodo =
    Return.map (\m -> ( getEditMode m, Return.singleton m ))
        >> Return.andThen (uncurry saveEditingTodoHelp)


saveEditingTodoHelp : EditMode -> ReturnMapper
saveEditingTodoHelp editMode =
    case editMode of
        EditTodoMode todo ->
            if Todo.isTextEmpty todo then
                identity
            else
                Return.andThen
                    (\m ->
                        TodoCollection.replaceTodoIfIdMatches todo m.todosModel
                            |> Tuple2.mapEach ((,) # m) persistTodoCmd
                    )
                    >> setTodosModelFromTuple

        _ ->
            identity


setTodosModelFromTuple =
    Return.map (\( todosModel, m ) -> { m | todosModel = todosModel })


persistTodoCmd todo =
    PouchDB.pouchDBBulkDocsHelp "todo-db" (Todo.encodeSingleton todo)
