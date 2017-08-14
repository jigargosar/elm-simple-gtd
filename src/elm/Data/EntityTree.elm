module Data.EntityTree exposing (..)

import Data.TodoDoc exposing (..)
import Entity exposing (..)
import Toolkit.Operators exposing (..)


type GroupDocEntityNode
    = GroupDocEntityNode GroupDocEntity (List TodoDoc)


type TodoListNode
    = TodoListNode String (List TodoDoc) Int


type Tree
    = GroupDocTree GroupDocEntityNode (List GroupDocEntityNode)
    | TodoList TodoListNode
    | GroupDocForest (List GroupDocEntityNode)
    | TodoListForest (List TodoListNode)


flatten : Tree -> List Entity
flatten tree =
    let
        getGroupDocNodeEntityList (GroupDocEntityNode gdEntity todoList) =
            Entity.GroupDocEntityW gdEntity :: (todoList .|> Entity.TodoEntity)
    in
    case tree of
        TodoList (TodoListNode _ todoList _) ->
            todoList .|> Entity.TodoEntity

        GroupDocTree (GroupDocEntityNode gdEntity todoList) nodeList ->
            [ Entity.GroupDocEntityW gdEntity ] ++ (nodeList |> List.concatMap getGroupDocNodeEntityList)

        GroupDocForest nodeList ->
            nodeList |> List.concatMap getGroupDocNodeEntityList

        TodoListForest nodeList ->
            nodeList |> List.concatMap (TodoList >> flatten)


createFlatTodoListNode stringTitle todoList totalCount =
    TodoListNode stringTitle todoList totalCount
        |> TodoList


createGroupDocEntityNode gdEntity todoList =
    GroupDocEntityNode gdEntity todoList


createGroupDocTree gdEntity todoList nodeList =
    GroupDocTree (GroupDocEntityNode gdEntity todoList) nodeList


createForest : List GroupDocEntityNode -> Tree
createForest =
    GroupDocForest


toEntityIdList tree =
    tree |> flatten .|> Entity.toEntityId
