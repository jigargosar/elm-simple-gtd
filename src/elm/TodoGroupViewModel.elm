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
    identity


groupedTodoLists__ =
    List.filter Todo.isNotDeleted
        >> Dict.groupBy (Todo.getListType >> toString)
        >> (\dict ->
                Todo.getAllTodoGroups
                    .|> (\group ->
                            ( Todo.todoGroupToName group, Dict.get (toString group) dict ?= [] )
                        )
           )
