module Model.TodoList exposing (..)

import Dict exposing (Dict)
import Dict.Extra
import Ext.Random
import List.Extra as List
import Maybe.Extra as Maybe
import Model
import Project
import Random.Pcg
import Time exposing (Time)
import Todo
import TodoList
import TodoList.Types exposing (..)
import Todo.Types exposing (..)
import Toolkit.Helpers exposing (..)
import Toolkit.Operators exposing (..)
import Ext.Function exposing (..)
import Ext.Function.Infix exposing (..)
import Model.Types exposing (..)
import Model.Internal exposing (..)
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


findTodoById : TodoId -> Model -> Maybe Todo
findTodoById id =
    getTodoList >> TodoList.findById id


findTodoEqualById todo =
    getTodoList >> List.find (Todo.equalById todo)


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


updateAndGetTodo : List TodoUpdateAction -> TodoId -> Model -> Maybe ( Todo, Model )
updateAndGetTodo actions todoId model =
    model
        |> findTodoById todoId
        ?|> (Todo.update actions (Model.getNow model)
                >> (\todo ->
                        let
                            newTodoList =
                                List.replaceIf (Todo.hasId todoId) todo model.todoList
                        in
                            ( todo
                            , setTodoList newTodoList model
                            )
                   )
            )


maybeTuple2With f model =
    f model ?|> (,) # model


addCopyOfTodo : Todo -> Time -> Model -> ( Todo, Model )
addCopyOfTodo todo now =
    Model.generate (getTodoList >> TodoList.addCopyOfTodoGenerator todo now)
        >> setTodoListFromTuple


addNewTodo : String -> Time -> Model -> ( Todo, Model )
addNewTodo text now =
    Model.generate (getTodoList >> TodoList.addNewTodoGenerator text now)
        >> setTodoListFromTuple


setTodoListFromTuple : ( ( Todo, TodoList ), Model ) -> ( Todo, Model )
setTodoListFromTuple ( ( todo, todoList ), model ) =
    ( todo, { model | todoList = todoList } )
