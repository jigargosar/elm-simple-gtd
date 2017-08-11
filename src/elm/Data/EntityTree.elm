module Data.EntityTree exposing (..)

import Data.TodoDoc exposing (..)
import Entity exposing (..)
import Toolkit.Operators exposing (..)


type GroupDocEntityNode
    = GroupDocEntityNode GroupDocEntity (List TodoDoc)


type Tree
    = GroupDocTree GroupDocEntityNode (List GroupDocEntityNode)
    | NamedTodoList String (List TodoDoc) Int
    | GroupDocForest (List GroupDocEntityNode)


flatten : Tree -> List Entity
flatten tree =
    let
        getGroupDocNodeEntityList (GroupDocEntityNode gdEntity todoList) =
            Entity.GroupDocEntityW gdEntity :: (todoList .|> Entity.TodoEntity)
    in
    case tree of
        NamedTodoList _ todoList _ ->
            todoList .|> Entity.TodoEntity

        GroupDocTree (GroupDocEntityNode gdEntity todoList) nodeList ->
            [ Entity.GroupDocEntityW gdEntity ] ++ (nodeList |> List.concatMap getGroupDocNodeEntityList)

        GroupDocForest nodeList ->
            nodeList |> List.concatMap getGroupDocNodeEntityList


createFlatTodoListNode stringTitle todoList totalCount =
    NamedTodoList stringTitle todoList totalCount


createGroupDocEntityNode gdEntity todoList =
    GroupDocEntityNode gdEntity todoList


createGroupDocTree gdEntity todoList nodeList =
    GroupDocTree (GroupDocEntityNode gdEntity todoList) nodeList


createForest : List GroupDocEntityNode -> Tree
createForest =
    GroupDocForest


toEntityIdList tree =
    tree |> flatten .|> Entity.toEntityId
