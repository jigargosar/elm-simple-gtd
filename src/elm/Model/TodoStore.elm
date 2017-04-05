module Model.TodoStore exposing (..)

import Dict exposing (Dict)
import Dict.Extra
import Ext.Random
import List.Extra as List
import Maybe.Extra as Maybe
import Model
import PouchDB
import Project
import Random.Pcg as Random
import Time exposing (Time)
import Todo
import Todo.Types exposing (..)
import Toolkit.Helpers exposing (..)
import Toolkit.Operators exposing (..)
import Ext.Function exposing (..)
import Ext.Function.Infix exposing (..)
import Model.Types exposing (..)
import Model.Internal as Model
import Types exposing (..)


getFilteredTodoList =
    apply2 ( getCurrentTodoListFilter, Model.getTodoStore >> PouchDB.asList )
        >> uncurry List.filter
        >> List.sortBy (Todo.getModifiedAt >> negate)


getCurrentTodoListFilter model =
    case Model.getMainViewType model of
        BinView ->
            Todo.binFilter

        DoneView ->
            Todo.doneFilter

        ProjectView projectId ->
            Todo.projectIdFilter projectId

        _ ->
            always (True)


findTodoById : TodoId -> Model -> Maybe Todo
findTodoById id =
    Model.getTodoStore >> PouchDB.findById id


findTodoEqualById todo =
    Model.getTodoStore >> PouchDB.asList >> List.find (Todo.equalById todo)


type alias TodoContextViewModel =
    { todoContext : TodoContext, name : String, todoList : List Todo, count : Int, isEmpty : Bool }


groupByTodoContextViewModel : Model -> List TodoContextViewModel
groupByTodoContextViewModel =
    Model.getTodoStore
        >> PouchDB.asList
        >> Todo.rejectAnyPass [ Todo.getDeleted, Todo.isDone ]
        >> Dict.Extra.groupBy (Todo.getTodoContext >> toString)
        >> (\dict ->
                Todo.getAllTodoContexts
                    .|> toViewModel dict
           )


toViewModel : Dict String (List Todo) -> TodoContext -> TodoContextViewModel
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


updateTodo : List TodoUpdateAction -> Todo -> ModelF
updateTodo action todo =
    apply2With ( Model.getNow, Model.getTodoStore )
        ((Todo.update action # todo)
            >> PouchDB.update
            >>> Model.setTodoStore
        )


updateTodoById actions todoId =
    applyMaybeWith (findTodoById todoId)
        (updateTodo actions)


replaceTodoIfEqualById todo =
    List.replaceIf (Todo.equalById todo) todo


addCopyOfTodo : Todo -> Time -> ModelF
addCopyOfTodo todo now =
    insertTodoByIdConstructor (Todo.copyTodo now todo)


addNewTodo : String -> Time -> ModelF
addNewTodo text now =
    insertTodoByIdConstructor (Todo.init now text)


insertTodoByIdConstructor constructWithId =
    applyWith (Model.getTodoStore)
        (PouchDB.insert (constructWithId) >> Model.setTodoStore)
