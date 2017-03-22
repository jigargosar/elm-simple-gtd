module Main.Model exposing (..)

import Json.Encode as E
import List.Extra as List
import Main.Msg exposing (..)
import Maybe.Extra as Maybe
import Navigation exposing (Location)
import RandomIdGenerator as Random
import Random.Pcg as Random exposing (Seed)
import Time exposing (Time)
import Todo as Todo exposing (EditMode(..), EncodedTodoList, Group, Todo, TodoId, TodoList)
import Toolkit.Operators exposing (..)
import Toolkit.Helpers exposing (..)
import Tuple2
import InboxFlow
import TodoStore exposing (TodoStore)
import TodoStore.Model


type ViewState
    = TodoListViewState
    | InboxFlowViewState (Maybe Todo) InboxFlow.Model


type alias Model =
    { now : Time
    , todoList : TodoList
    , editMode : EditMode
    , viewState : ViewState
    , seed : Seed
    }


modelConstructor now todoList editMode ( todoStore, seed ) =
    Model now todoList editMode TodoListViewState seed


type alias ModelMapper =
    Model -> Model


init : Time -> EncodedTodoList -> Model
init now encodedTodoList =
    let
        todoList =
            Todo.decodeTodoList encodedTodoList

        generateTodoModel =
            todoList |> TodoStore.generator >> Random.step

        todoModelFromSeed =
            Random.seedFromTime >> generateTodoModel
    in
        now
            |> todoModelFromSeed
            >> modelConstructor now todoList NotEditing


setViewState viewState m =
    { m | viewState = viewState }


getNow =
    .now


getViewState =
    (.viewState)


getTodoList : Model -> TodoList
getTodoList =
    (.todoList)


setTodoList : TodoList -> ModelMapper
setTodoList todoList model =
    { model | todoList = todoList }


updateTodoList : (Model -> TodoList) -> ModelMapper
updateTodoList updater model =
    setTodoList (updater model) model


getFirstInboxTodo =
    getTodoList >> Todo.getFirstInboxTodo


showTodoList =
    setViewState TodoListViewState


mapAllExceptDeleted mapper =
    getTodoList >> Todo.mapAllExceptDeleted mapper


startProcessingInbox model =
    mapAllExceptDeleted identity model
        |> InboxFlow.init
        |> InboxFlowViewState (getFirstInboxTodo model)
        |> (setViewState # model)


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
                addNewTodoHelp now text m

        _ ->
            ( m, Nothing )


addNewTodoHelp : Time -> String -> Model -> ( Model, Maybe Todo )
addNewTodoHelp createdAt text model =
    let
        foo : ( Seed, Todo )
        foo =
            Random.step (Todo.generator createdAt text) (getSeed model)
                |> Tuple2.swap
    in
        foo
            |> Tuple.mapFirst (setSeed # model)
            |> (\( model, todo ) -> ( updateTodoList (getTodoList >> (::) todo) model, Just todo ))


getSeed : Model -> Seed
getSeed =
    (.seed)


setSeed : Seed -> ModelMapper
setSeed seed model =
    { model | seed = seed }


updateSeed : (Model -> Seed) -> ModelMapper
updateSeed updater model =
    setSeed (updater model) model


updateTodo : TodoStore.Model.Action -> TodoId -> Model -> ( Model, Cmd msg )
updateTodo action todoId m =
    --    TodoStore.editTodo action todoId m.todoStore
    --        |> Tuple2.mapFirst (setTodoCollection # m)
    ( m, Cmd.none )


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


replaceTodoIfIdMatches2 : Time -> Todo -> Model -> ( Model, Todo )
replaceTodoIfIdMatches2 now todo =
    let
        updatedTodoWithModifiedAt =
            Todo.setModifiedAt now todo

        newTodoList =
            getTodoList >> Todo.replaceIfEqualById updatedTodoWithModifiedAt
    in
        updateTodoList newTodoList >> (,) # updatedTodoWithModifiedAt


replaceTodoIfIdMatches : Time -> Todo -> Model -> ( Model, Maybe Todo )
replaceTodoIfIdMatches now todo m =
    --    replaceTodoIfIdMatches2 now todo m.todoStore
    --        |> Tuple2.mapEach (setTodoCollection # m) (Just)
    ( m, Nothing )



--deleteMaybeTodo : Maybe Todo -> Model -> ( Model, Maybe Todo )
--deleteMaybeTodo maybeTodo model =
--    maybeTodo
--        ?|> (Todo.getId >> deleteTodo # model)
--        ?= ( model, Nothing )
--deleteTodoInboxFlow m =
--    m
--        |> case getViewState m of
--            InboxFlowViewState maybeTodo inboxFlowModel ->
--                deleteMaybeTodo maybeTodo
--                    >> Tuple.mapFirst startProcessingInbox
--
--            _ ->
--                (,) # Nothing


updateInboxFlowWithActionType actionType m =
    m
        |> case getViewState m of
            InboxFlowViewState maybeTodo inboxFlowModel ->
                InboxFlow.updateWithActionType actionType inboxFlowModel
                    |> InboxFlowViewState maybeTodo
                    |> setViewState

            _ ->
                identity


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
