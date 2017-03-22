module Main.Model exposing (..)

import Json.Encode as E
import List.Extra as List
import Main.Msg exposing (..)
import Maybe.Extra as Maybe
import Navigation exposing (Location)
import RandomIdGenerator as Random
import Random.Pcg as Random exposing (Seed)
import Time exposing (Time)
import Todo as Todo exposing (EditMode(..), EncodedTodoList, Group, Todo, TodoId)
import Toolkit.Operators exposing (..)
import Toolkit.Helpers exposing (..)
import Tuple2
import InboxFlow
import TodoStore exposing (TodoStore)


type ViewState
    = TodoListViewState
    | InboxFlowViewState (Maybe Todo) InboxFlow.Model


type alias Model =
    { now : Time
    , todoStore : TodoStore
    , editMode : EditMode
    , viewState : ViewState
    }


modelConstructor now editMode todoStore =
    Model now todoStore editMode TodoListViewState


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
            >> (modelConstructor now NotEditing)


setViewState viewState m =
    { m | viewState = viewState }


getNow =
    .now


getViewState =
    (.viewState)


getFirstInboxTodo =
    getTodoCollection >> TodoStore.getFirstInboxTodo


showTodoList =
    setViewState TodoListViewState


startProcessingInbox model =
    getTodoCollection model
        |> TodoStore.getInbox__
        |> InboxFlow.init
        |> InboxFlowViewState (getFirstInboxTodo model)
        |> (setViewState # model)


updateInboxFlowWithActionType actionType m =
    m
        |> case getViewState m of
            InboxFlowViewState maybeTodo inboxFlowModel ->
                InboxFlow.updateWithActionType actionType inboxFlowModel
                    |> InboxFlowViewState maybeTodo
                    |> setViewState

            _ ->
                identity



--deleteMaybeTodo : Maybe Todo -> Model -> ( Model, Maybe Todo )
--deleteMaybeTodo maybeTodo model =
--    maybeTodo
--        ?|> (Todo.getId >> deleteTodo # model)
--        ?= ( model, Nothing )


moveTodoToListType now listType todo m =
    Todo.setListType listType todo
        |> ((replaceTodoIfIdMatches now) # m)


moveMaybeTodoToListType : Time -> Group -> Maybe Todo -> Model -> ( Model, Maybe Todo )
moveMaybeTodoToListType now listType maybeTodo model =
    maybeTodo
        ?|> ((moveTodoToListType now listType) # model)
        ?= ( model, Nothing )


moveInboxProcessingTodoToListType now listType m =
    m
        |> case getViewState m of
            InboxFlowViewState maybeTodo inboxFlowModel ->
                moveMaybeTodoToListType now listType maybeTodo
                    >> Tuple.mapFirst startProcessingInbox

            _ ->
                (,) # Nothing



--deleteTodoInboxFlow m =
--    m
--        |> case getViewState m of
--            InboxFlowViewState maybeTodo inboxFlowModel ->
--                deleteMaybeTodo maybeTodo
--                    >> Tuple.mapFirst startProcessingInbox
--
--            _ ->
--                (,) # Nothing


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

                    InboxFlowViewState _ _ ->
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


addNewTodoAndContinueAdding : Time -> Model -> ( Model, Maybe Todo )
addNewTodoAndContinueAdding now =
    addNewTodo now
        >> Tuple2.mapFirst (activateAddNewTodoMode "")


addNewTodo : Time -> Model -> ( Model, Maybe Todo )
addNewTodo now m =
    case getEditMode m of
        EditNewTodoMode text ->
            if String.trim text |> String.isEmpty then
                ( m, Nothing )
            else
                TodoStore.addNewTodo now text m.todoStore
                    |> Tuple2.mapEach (setTodoCollection # m) (Just)

        _ ->
            ( m, Nothing )


deleteTodo todoId m =
    updateTodo TodoStore.deleteAction todoId m


updateTodo action todoId m =
    TodoStore.editTodo action todoId m.todoStore
        |> Tuple2.mapFirst (setTodoCollection # m)


saveEditingTodoAndDeactivateEditTodoMode : Time -> Model -> ( Model, Maybe Todo )
saveEditingTodoAndDeactivateEditTodoMode now =
    saveEditingTodo now
        >> Tuple2.mapFirst deactivateEditingMode


deactivateEditingMode =
    setEditModeTo NotEditing


saveEditingTodo : Time -> Model -> ( Model, Maybe Todo )
saveEditingTodo now m =
    case getEditMode m of
        EditTodoMode todo ->
            if Todo.isTextEmpty todo then
                ( m, Nothing )
            else
                replaceTodoIfIdMatches now todo m

        _ ->
            ( m, Nothing )


replaceTodoIfIdMatches now todo m =
    TodoStore.replaceTodoIfIdMatches now todo m.todoStore
        |> Tuple2.mapEach (setTodoCollection # m) (Just)
