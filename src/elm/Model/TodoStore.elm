module Model.TodoStore exposing (..)

import Context
import Dict exposing (Dict)
import Dict.Extra
import Document exposing (Id)
import Ext.Random
import List.Extra as List
import Maybe.Extra as Maybe
import Project
import Random.Pcg as Random
import Store
import Time exposing (Time)
import Todo
import Toolkit.Helpers exposing (..)
import Toolkit.Operators exposing (..)
import Ext.Function exposing (..)
import Ext.Function.Infix exposing (..)
import Model.Types exposing (..)
import Model.Internal as Model
import Types exposing (..)


getFilteredTodoList =
    apply2 ( getCurrentTodoListFilter, Model.getTodoStore >> Store.asList )
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


findTodoById : Todo.Id -> Model -> Maybe Todo.Model
findTodoById id =
    Model.getTodoStore >> Store.findById id


type alias TodoContextViewModel =
    { name : String, todoList : List Todo.Model, count : Int, isEmpty : Bool }


groupByTodoContextViewModel : Model -> List TodoContextViewModel
groupByTodoContextViewModel =
    Model.getTodoStore
        >> Store.asList
        >> Todo.rejectAnyPass [ Todo.isDeleted, Todo.isDone ]
        --        >> Dict.Extra.groupBy (Todo.getTodoContext >> toString)
        >> Dict.Extra.groupBy (\_ -> "Inbox")
        >> (\dict ->
                --                Todo.getAllTodoContexts
                [ "Inbox" ]
                    .|> (apply2
                            ( identity
                            , (Dict.get # dict >> Maybe.withDefault [])
                            )
                            >> (\( name, list ) ->
                                    list
                                        |> apply3 ( identity, List.length, List.isEmpty )
                                        >> uncurry3 (TodoContextViewModel name)
                               )
                        )
           )


updateTodo : List Todo.UpdateAction -> Todo.Model -> ModelF
updateTodo action todo =
    apply2With ( Model.getNow, Model.getTodoStore )
        ((Todo.update action # todo)
            >> Store.update
            >>> Model.setTodoStore
        )


updateTodoById actions todoId =
    applyMaybeWith (findTodoById todoId)
        (updateTodo actions)


replaceTodoIfEqualById todo =
    List.replaceIf (Document.equalById todo) todo


addCopyOfTodo : Todo.Model -> Time -> Model -> ( Todo.Model, Model )
addCopyOfTodo todo now =
    insertTodoByIdConstructor (Todo.copyTodo now todo)


addNewTodo : String -> Time -> Model -> ( Todo.Model, Model )
addNewTodo text now =
    insertTodoByIdConstructor (Todo.init now text)


insertTodoByIdConstructor : (Id -> Todo.Model) -> Model -> ( Todo.Model, Model )
insertTodoByIdConstructor constructWithId =
    applyWith (Model.getTodoStore)
        (Store.insert (constructWithId) >> setTodoStoreFromTuple)


setTodoStoreFromTuple tuple model =
    tuple |> Tuple.mapSecond (Model.setTodoStore # model)
