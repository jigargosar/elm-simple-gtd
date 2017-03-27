module TodoGroupViewModel exposing (..)

import Dict exposing (Dict)
import Dict.Extra as Dict
import Todo exposing (TodoGroup, TodoList)
import Toolkit.Helpers exposing (..)
import Toolkit.Operators exposing (..)
import FunctionExtra exposing (..)
import Main.Model as Model
import Types exposing (Model)


type alias TodoGroupViewModel =
    { group : TodoGroup, name : String, todoList : TodoList, count : Int, isEmpty : Bool }


getTodoGroupsViewModel : Model -> List TodoGroupViewModel
getTodoGroupsViewModel =
    Model.getTodoList
        >> Todo.rejectAnyPass [ Todo.isDeleted, Todo.isDone ]
        >> Dict.groupBy (Todo.getGroup >> toString)
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
