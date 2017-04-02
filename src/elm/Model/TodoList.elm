module Model.TodoList exposing (..)

import Dict exposing (Dict)
import Dict.Extra
import List.Extra as List
import Maybe.Extra as Maybe
import Model
import Project
import Todo
import TodoList
import TodoList.Types exposing (..)
import Todo.Types exposing (..)
import Toolkit.Helpers exposing (..)
import Toolkit.Operators exposing (..)
import FunctionExtra exposing (..)
import Model.Types exposing (..)
import Types exposing (..)


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


getTodoById : TodoId -> Model -> Maybe Todo
getTodoById id =
    getTodoList >> TodoList.findById id


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


type alias TodoContextViewModel =
    { todoContext : TodoContext, name : String, todoList : TodoList, count : Int, isEmpty : Bool }


getTodoContextsViewModel : Model -> List TodoContextViewModel
getTodoContextsViewModel =
    getTodoList
        >> Todo.rejectAnyPass [ Todo.getDeleted, Todo.isDone ]
        >> Dict.Extra.groupBy (Todo.getTodoContext >> toString)
        >> (\dict ->
                Todo.getAllTodoContexts
                    .|> toViewModel dict
           )


toViewModel : Dict String TodoList -> TodoContext -> TodoContextViewModel
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


updateAndGetTodo : List TodoUpdateAction -> TodoId -> Model -> ( Maybe Todo, Model )
updateAndGetTodo actions todoId model =
    let
        updater =
            Todo.update actions (Model.getNow model)

        newTodoList =
            model.todoList
                |> List.updateIf (Todo.hasId todoId) updater
    in
        ( List.find (Todo.hasId todoId) newTodoList
        , setTodoList newTodoList model
        )
