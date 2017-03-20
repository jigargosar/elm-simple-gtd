module Main.Model exposing (..)

import Json.Encode as E
import List.Extra as List
import Main.Msg exposing (..)
import Maybe.Extra as Maybe
import Navigation exposing (Location)
import RandomIdGenerator as Random
import Random.Pcg as Random exposing (Seed)
import Time exposing (Time)
import Todo as Todo exposing (EditMode(..), EncodedTodoList, Todo, TodoId)
import Toolkit.Operators exposing (..)
import Toolkit.Helpers exposing (..)
import Tuple2
import InBasketFlow
import TodoStore exposing (TodoStore)


type ViewState
    = TodoListViewState
    | InBasketFlowViewState (Maybe Todo) InBasketFlow.Model


type alias Model =
    { todoStore : TodoStore
    , editMode : EditMode
    , viewState : ViewState
    }


modelConstructor editMode todoStore =
    Model todoStore editMode TodoListViewState


type alias ModelMapper =
    Model -> Model


init : Time -> EncodedTodoList -> Model
init now encodedTodoList =
    let
        generateTodoModel =
            Todo.decodeTodoList
                >> TodoStore.generator
                >> Random.step

        todoModelFromSeed =
            Random.seedFromTime >> generateTodoModel encodedTodoList >> Tuple.first
    in
        now
            |> todoModelFromSeed
            >> (modelConstructor NotEditing)


setViewState viewState m =
    { m | viewState = viewState }


getViewState =
    (.viewState)


getFirstInBasketTodo =
    getTodoCollection >> TodoStore.getFirstInBasketTodo


showTodoList =
    setViewState TodoListViewState


startProcessingInBasket model =
    getTodoCollection model
        |> TodoStore.getInBasket__
        |> InBasketFlow.init
        |> InBasketFlowViewState (getFirstInBasketTodo model)
        |> (setViewState # model)


updateInBasketFlowWithActionType actionType m =
    m
        |> case getViewState m of
            InBasketFlowViewState maybeTodo inBasketFlowModel ->
                InBasketFlow.updateWithActionType actionType inBasketFlowModel
                    |> InBasketFlowViewState maybeTodo
                    |> setViewState

            _ ->
                identity


moveTodoToUnder2mList : Maybe Todo -> Model -> ( Model, Maybe Todo )
moveTodoToUnder2mList maybeTodo model =
    maybeTodo
        ?|> (Todo.setContextUnder2m >> (replaceTodoIfIdMatches # model))
        ?= ( model, Nothing )


deleteMaybeTodo : Maybe Todo -> Model -> ( Model, Maybe Todo )
deleteMaybeTodo maybeTodo model =
    maybeTodo
        ?|> (Todo.getId >> deleteTodo # model)
        ?= ( model, Nothing )


moveInBasketProcessingTodoToUnder2mList m =
    m
        |> case getViewState m of
            InBasketFlowViewState maybeTodo inBasketFlowModel ->
                moveTodoToUnder2mList maybeTodo
                    >> Tuple.mapFirst startProcessingInBasket

            _ ->
                (,) # Nothing


deleteTodoInBasketFlow m =
    m
        |> case getViewState m of
            InBasketFlowViewState maybeTodo inBasketFlowModel ->
                deleteMaybeTodo maybeTodo
                    >> Tuple.mapFirst startProcessingInBasket

            _ ->
                (,) # Nothing


getTodoCollection : Model -> TodoStore
getTodoCollection =
    (.todoStore)


setEditModeTo : EditMode -> ModelMapper
setEditModeTo editMode m =
    { m | editMode = editMode }


getEditMode : Model -> EditMode
getEditMode =
    (.editMode)


getSelectedTabIndex : Model -> Int
getSelectedTabIndex =
    getViewState
        >> (\vs ->
                case vs of
                    TodoListViewState ->
                        0

                    InBasketFlowViewState ->
                        1
           )


activateAddNewTodoMode : String -> ModelMapper
activateAddNewTodoMode text =
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


setTodoCollection : TodoStore -> ModelMapper
setTodoCollection todoStore m =
    { m | todoStore = todoStore }


updateTodoCollection : (Model -> TodoStore) -> ModelMapper
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
                TodoStore.addNewTodo text m.todoStore
                    |> Tuple2.mapEach (setTodoCollection # m) (Just)

        _ ->
            ( m, Nothing )


deleteTodo todoId m =
    TodoStore.deleteTodo todoId m.todoStore
        |> Tuple2.mapFirst (setTodoCollection # m)


saveEditingTodoAndDeactivateEditTodoMode : Model -> ( Model, Maybe Todo )
saveEditingTodoAndDeactivateEditTodoMode =
    saveEditingTodo
        >> Tuple2.mapFirst deactivateEditingMode


deactivateEditingMode =
    setEditModeTo NotEditing


saveEditingTodo : Model -> ( Model, Maybe Todo )
saveEditingTodo m =
    case getEditMode m of
        EditTodoMode todo ->
            if Todo.isTextEmpty todo then
                ( m, Nothing )
            else
                replaceTodoIfIdMatches todo m

        _ ->
            ( m, Nothing )


replaceTodoIfIdMatches todo m =
    TodoStore.replaceTodoIfIdMatches todo m.todoStore
        |> Tuple2.mapEach (setTodoCollection # m) (Just)
