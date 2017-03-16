module Main.Model exposing (..)

import Json.Encode as E
import List.Extra as List
import Maybe.Extra as Maybe
import Navigation exposing (Location)
import RandomIdGenerator as Random
import TodoCollection exposing (EditMode(..), TodoCollection)
import Random.Pcg as Random exposing (Seed)
import Time exposing (Time)
import TodoCollection.Todo as Todo exposing (EncodedTodoList, Todo, TodoId)
import Toolkit.Operators exposing (..)
import Toolkit.Helpers exposing (..)
import Tuple2


type ProcessingModel
    = NotProcessing
    | StartProcessing Int (List Todo) Todo
    | ProcessAsActionable Int (List Todo) Todo


type alias Model =
    { todoCollection : TodoCollection
    , editMode : EditMode
    , processingModel : ProcessingModel
    }


modelConstructor editMode todoCollection =
    Model todoCollection editMode NotProcessing


type alias ModelMapper =
    Model -> Model


init : Time -> EncodedTodoList -> Model
init now encodedTodoList =
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


getTodoCollection : Model -> TodoCollection
getTodoCollection =
    (.todoCollection)


setEditModeTo : EditMode -> ModelMapper
setEditModeTo editMode m =
    { m | editMode = editMode }


getEditMode : Model -> EditMode
getEditMode =
    (.editMode)


activateAddNewTodoMode : String -> ModelMapper
activateAddNewTodoMode text =
    setEditModeTo (EditNewTodoMode text)


activateEditTodoMode : Todo -> ModelMapper
activateEditTodoMode todo =
    setEditModeTo (EditTodoMode todo)


activateProcessingMode : ModelMapper
activateProcessingMode m =
    setProcessingModel (startProcessing (getTodoCollection m |> TodoCollection.asList)) m


setProcessingModel processingModel m =
    { m | processingModel = processingModel }


startProcessing todoList =
    todoList |> List.getAt 0 ?|> StartProcessing 0 todoList ?= NotProcessing


processAsActionable bool m =
    (case (m.processingModel) of
        StartProcessing idx list todo ->
            ProcessAsActionable idx list todo

        _ ->
            NotProcessing
    )
        |> (setProcessingModel # m)


getProcessingModel =
    (.processingModel)


updateEditTodoText : String -> ModelMapper
updateEditTodoText text m =
    case getEditMode m of
        EditTodoMode todo ->
            setEditModeTo (EditTodoMode (Todo.setText text todo)) m

        _ ->
            m


setTodoCollection : TodoCollection -> ModelMapper
setTodoCollection todoCollection m =
    { m | todoCollection = todoCollection }


updateTodoCollection : (Model -> TodoCollection) -> ModelMapper
updateTodoCollection fun model =
    setTodoCollection (fun model) model


addNewTodoAndDeactivateAddNewTodoMode : Model -> ( Model, Maybe Todo )
addNewTodoAndDeactivateAddNewTodoMode =
    addNewTodo
        >> Tuple2.mapFirst (setEditModeTo NotEditing)


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
                TodoCollection.addNewTodo text m.todoCollection
                    |> Tuple2.mapEach (setTodoCollection # m) (Just)

        _ ->
            ( m, Nothing )


deleteTodo todoId m =
    TodoCollection.deleteTodo todoId m.todoCollection
        |> Tuple2.mapFirst (setTodoCollection # m)


saveEditingTodoAndDeactivateEditTodoMode : Model -> ( Model, Maybe Todo )
saveEditingTodoAndDeactivateEditTodoMode =
    saveEditingTodo
        >> Tuple2.mapFirst (setEditModeTo NotEditing)


saveEditingTodo : Model -> ( Model, Maybe Todo )
saveEditingTodo m =
    case getEditMode m of
        EditTodoMode todo ->
            if Todo.isTextEmpty todo then
                ( m, Nothing )
            else
                TodoCollection.replaceTodoIfIdMatches todo m.todoCollection
                    |> Tuple2.mapEach (setTodoCollection # m) (Just)

        _ ->
            ( m, Nothing )
