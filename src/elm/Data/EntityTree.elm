module Data.EntityTree exposing (..)

import Data.TodoDoc exposing (..)
import Document
import Entity exposing (..)
import GroupDoc exposing (..)
import List.Extra as List
import Toolkit.Operators exposing (..)
import X.Function exposing (..)


type GroupDocNode
    = GroupDocNode GroupDocEntity (List TodoDoc)


type Title
    = GroupDocEntityTitle GroupDocEntity
    | StringTitle String


type Node
    = Node Title (List TodoDoc) Int


type Tree
    = RootNode GroupDocNode (List GroupDocNode)
    | SingleNode Node
    | Forest (List GroupDocNode)


flatten : Tree -> List Entity
flatten tree =
    let
        getNodeEntityList node =
            case node of
                Node (GroupDocEntityTitle gdEntity) todoList _ ->
                    Entity.GroupDocEntityW gdEntity :: (todoList .|> Entity.TodoEntity)

                Node (StringTitle _) todoList _ ->
                    todoList .|> Entity.TodoEntity

        getGroupDocNodeEntityList (GroupDocNode gdEntity todoList) =
            Entity.GroupDocEntityW gdEntity :: (todoList .|> Entity.TodoEntity)
    in
    case tree of
        SingleNode node ->
            getNodeEntityList node

        RootNode (GroupDocNode gdEntity todoList) nodeList ->
            [ Entity.GroupDocEntityW gdEntity ] ++ (nodeList |> List.concatMap getGroupDocNodeEntityList)

        Forest nodeList ->
            nodeList |> List.concatMap getGroupDocNodeEntityList


createRootLeafNodeWithStringTitle stringTitle todoList totalCount =
    SingleNode (Node (StringTitle stringTitle) todoList totalCount)


createGroupDocEntityNode gdEntity todoList =
    GroupDocNode gdEntity todoList


createRootGroupDocEntityNode gdEntity todoList nodeList =
    RootNode (GroupDocNode gdEntity todoList) nodeList


createForest : List GroupDocNode -> Tree
createForest =
    Forest
