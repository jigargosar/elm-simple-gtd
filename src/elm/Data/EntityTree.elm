module Data.EntityTree exposing (..)

import Data.TodoDoc exposing (..)
import Document
import Entity exposing (..)
import GroupDoc exposing (..)
import List.Extra as List
import Toolkit.Operators exposing (..)
import X.Function exposing (..)


type GroupDocEntityNode
    = GroupDocNode GroupDocEntity (List TodoDoc)


type Tree
    = GroupDocTree GroupDocNode (List GroupDocNode)
    | NamedTodoList String (List TodoDoc) Int
    | GroupDocForest (List GroupDocNode)


flatten : Tree -> List Entity
flatten tree =
    let
        getGroupDocNodeEntityList (GroupDocNode gdEntity todoList) =
            Entity.GroupDocEntityW gdEntity :: (todoList .|> Entity.TodoEntity)
    in
    case tree of
        NamedTodoList _ todoList _ ->
            todoList .|> Entity.TodoEntity

        GroupDocTree (GroupDocNode gdEntity todoList) nodeList ->
            [ Entity.GroupDocEntityW gdEntity ] ++ (nodeList |> List.concatMap getGroupDocNodeEntityList)

        GroupDocForest nodeList ->
            nodeList |> List.concatMap getGroupDocNodeEntityList


createFlatTodoListNode stringTitle todoList totalCount =
    NamedTodoList stringTitle todoList totalCount


createGroupDocEntityNode gdEntity todoList =
    GroupDocNode gdEntity todoList


createGroupDocTree gdEntity todoList nodeList =
    GroupDocTree (GroupDocNode gdEntity todoList) nodeList


createForest : List GroupDocNode -> Tree
createForest =
    GroupDocForest
