module TodoGroupViewModel exposing (..)

import Dict
import Dict.Extra as Dict
import Todo exposing (TodoGroup, TodoList)
import Toolkit.Helpers exposing (..)
import Toolkit.Operators exposing (..)
import FunctionExtra exposing (..)


type alias TodoGroupViewModel =
    { group : TodoGroup, displayName : String, todoList : TodoList }


getTodoGroupsViewModel =
    List.filter Todo.isNotDeleted
        >> Dict.groupBy (Todo.getGroup >> toString)
        >> (\dict ->
                Todo.getAllTodoGroups
                    .|> toViewModel dict
           )


toViewModel dict =
    apply3
        ( identity
        , Todo.groupToName
        , toString >> Dict.get # dict ?= []
        )
