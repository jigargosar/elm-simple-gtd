module TodoGroupViewModel exposing (..)

import Dict exposing (Dict)
import Dict.Extra as Dict
import Todo exposing (TodoGroup, TodoList)
import Toolkit.Helpers exposing (..)
import Toolkit.Operators exposing (..)
import FunctionExtra exposing (..)


type alias TodoGroupViewModel =
    { group : TodoGroup, displayName : String, todoList : TodoList }


getTodoGroupsViewModel : TodoList -> List TodoGroupViewModel
getTodoGroupsViewModel =
    List.filter Todo.isNotDeleted
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
        >> uncurry3 TodoGroupViewModel
