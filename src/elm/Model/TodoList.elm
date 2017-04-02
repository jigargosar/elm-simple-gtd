module Model.TodoList exposing (..)

import Dict exposing (Dict)
import Dict.Extra
import List.Extra as List
import Maybe.Extra as Maybe
import Model
import Project
import Todo
import TodoListModel.Types exposing (..)
import Todo.Types exposing (..)
import Toolkit.Helpers exposing (..)
import Toolkit.Operators exposing (..)
import FunctionExtra exposing (..)
import Model.Types exposing (..)
import Types exposing (..)


getTodoList : Model -> TodoListModel
getTodoList =
    (.todoList)


getFilteredTodoList =
    apply2 ( getCurrentTodoListFilter, getTodoList )
        >> uncurry List.filter
        >> List.sortBy (Todo.getModifiedAt >> negate)


getCurrentTodoListFilter model =
    case Model.getMainViewType model of
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


getTodoById : TodoId -> Model -> Maybe TodoModel
getTodoById id =
    getTodoList >> Todo.findById id


findTodoEqualById todo =
    getTodoList >> List.find (Todo.equalById todo)


addTodo todo =
    updateTodoList (getTodoList >> (::) todo)


setTodoList : TodoListModel -> ModelF
setTodoList todoList model =
    { model | todoList = todoList }


updateTodoList : (Model -> TodoListModel) -> ModelF
updateTodoList updater model =
    setTodoList (updater model) model


updateTodoMaybe : (TodoModel -> TodoModel) -> TodoId -> Model -> ( Maybe TodoModel, Model )
updateTodoMaybe updater todoId m =
    let
        newTodoList =
            m.todoList
                |> List.updateIf (Todo.hasId todoId) updater
    in
        ( List.find (Todo.hasId todoId) newTodoList
        , setTodoList newTodoList m
        )


type alias TodoContextViewModel =
    { todoContext : TodoContext, name : String, todoList : TodoListModel, count : Int, isEmpty : Bool }


getTodoContextsViewModel : Model -> List TodoContextViewModel
getTodoContextsViewModel =
    getTodoList
        >> Todo.rejectAnyPass [ Todo.getDeleted, Todo.isDone ]
        >> Dict.Extra.groupBy (Todo.getTodoContext >> toString)
        >> (\dict ->
                Todo.getAllTodoContexts
                    .|> toViewModel dict
           )


toViewModel : Dict String TodoListModel -> TodoContext -> TodoContextViewModel
toViewModel dict =
    apply3
        ( identity
        , Todo.todoContextToName
        , (toString >> Dict.get # dict >> Maybe.withDefault [])
        )
        >> toViewModelHelp


toViewModelHelp ( todoContext, name, list ) =
    list
        |> apply3 ( identity, List.length, List.isEmpty )
        >> uncurry3 (TodoContextViewModel todoContext name)


updateTodoWithFields : List TodoField -> TodoId -> Model -> ( Maybe TodoModel, Model )
updateTodoWithFields fields =
    updateTodoMaybe (Todo.setFields fields)


updateAndGetMaybeTodo fields todoId model =
    model |> getTodoById todoId ?|> Todo.setFields fields


upsertTodo todo model =
    let
        maybeIndex =
            model |> getTodoList >> List.findIndex (Todo.equalById todo)
    in
        case maybeIndex of
            Nothing ->
                addTodo todo model

            Just index ->
                updateTodoList
                    (\m ->
                        let
                            tl =
                                getTodoList m
                        in
                            tl |> List.setAt index todo ?= tl
                    )
                    model
