module Model.TodoList exposing (..)

import Dict exposing (Dict)
import Dict.Extra
import List.Extra as List
import Model
import Todo exposing (Todo, TodoGroup, TodoId, TodoList)
import Toolkit.Helpers exposing (..)
import Toolkit.Operators exposing (..)
import FunctionExtra exposing (..)
import Types exposing (MainViewType(..), Model, ModelF, TodoField)


getTodoList : Model -> TodoList
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


getTodoById : TodoId -> Model -> Maybe Todo
getTodoById id =
    getTodoList >> Todo.findById id


findTodoEqualById todo =
    getTodoList >> List.find (Todo.equalById todo)


addTodo todo =
    updateTodoList (getTodoList >> (::) todo)


setTodoList : TodoList -> ModelF
setTodoList todoList model =
    { model | todoList = todoList }


updateTodoList : (Model -> TodoList) -> ModelF
updateTodoList updater model =
    setTodoList (updater model) model


updateTodoMaybe : (Todo -> Todo) -> TodoId -> Model -> ( Maybe Todo, Model )
updateTodoMaybe updater todoId m =
    let
        newTodoList =
            m.todoList
                |> List.updateIf (Todo.hasId todoId) updater
    in
        ( List.find (Todo.hasId todoId) newTodoList
        , setTodoList newTodoList m
        )


type alias TodoGroupViewModel =
    { group : TodoGroup, name : String, todoList : TodoList, count : Int, isEmpty : Bool }


getTodoGroupsViewModel : Model -> List TodoGroupViewModel
getTodoGroupsViewModel =
    getTodoList
        >> Todo.rejectAnyPass [ Todo.isDeleted, Todo.isDone ]
        >> Dict.Extra.groupBy (Todo.getGroup >> toString)
        >> (\dict ->
                Todo.getAllTodoGroups
                    .|> toViewModel dict
           )


toViewModel : Dict String TodoList -> TodoGroup -> TodoGroupViewModel
toViewModel dict =
    apply3
        ( identity
        , Todo.groupToName
        , (toString >> Dict.get # dict >> Maybe.withDefault [])
        )
        >> toViewModelHelp


toViewModelHelp ( group, name, list ) =
    list
        |> apply3 ( identity, List.length, List.isEmpty )
        >> uncurry3 (TodoGroupViewModel group name)


updateTodoWithFields : List TodoField -> TodoId -> Model -> ( Maybe Todo, Model )
updateTodoWithFields fields =
    updateTodoMaybe (updateFields fields)


updateFields fields =
    List.foldl updateField # fields


updateField field =
    case field of
        Types.TodoText text ->
            Todo.setText text

        _ ->
            identity
