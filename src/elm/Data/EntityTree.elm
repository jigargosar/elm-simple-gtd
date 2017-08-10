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
    = RootNode GroupDocNode (List Node)
    | SingleNode Node
    | Forest (List Node)


flatten : Tree -> List Entity
flatten tree =
    let
        getNodeEntityList node =
            case node of
                Node (GroupDocEntityTitle gdEntity) todoList _ ->
                    Entity.GroupDocEntityW gdEntity :: (todoList .|> Entity.TodoEntity)

                Node (StringTitle _) todoList _ ->
                    todoList .|> Entity.TodoEntity
    in
    case tree of
        SingleNode node ->
            getNodeEntityList node

        RootNode (GroupDocNode gdEntity todoList) nodeList ->
            [ Entity.GroupDocEntityW gdEntity ] ++ (nodeList |> List.concatMap getNodeEntityList)

        Forest nodeList ->
            nodeList |> List.concatMap getNodeEntityList


createRootLeafNodeWithStringTitle stringTitle todoList totalCount =
    SingleNode (Node (StringTitle stringTitle) todoList totalCount)


createGroupDocEntityNode gdEntity todoList totalCount =
    Node (GroupDocEntityTitle gdEntity) todoList totalCount


createRootGroupDocEntityNode gdEntity todoList nodeList =
    RootNode (GroupDocNode gdEntity todoList) nodeList


createForest : List Node -> Tree
createForest =
    Forest
