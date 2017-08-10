module Data.EntityTree exposing (..)

import Data.TodoDoc exposing (..)
import Document
import Entity exposing (..)
import GroupDoc exposing (..)
import List.Extra as List
import Toolkit.Operators exposing (..)
import X.Function exposing (..)


type alias ContextNode =
    { context : ContextDoc
    , todoList : List TodoDoc
    }


type alias ProjectNode =
    { project : ProjectDoc
    , todoList : List TodoDoc
    }


type GroupDocNode
    = GroupDocNode GroupDocEntity (List TodoDoc)


type Title
    = GroupDocEntityTitle GroupDocEntity
    | StringTitle String


type Node
    = Node Title (List TodoDoc) Int


type Tree
    = ContextRoot ContextNode (List ProjectNode)
    | ProjectRoot ProjectNode (List ContextNode)
    | RootNode Node (List Node)
    | SingleNode Node
    | Forest (List Node)


initContextNode getTodoList context =
    { context = context
    , todoList = getTodoList context
    }


initProjectNode getTodoList project =
    { project = project
    , todoList = getTodoList project
    }


createProjectSubGroups findProjectById tcg =
    let
        projects =
            tcg.todoList
                .|> Data.TodoDoc.getProjectId
                |> List.unique
                .|> findProjectById
                |> List.filterMap identity
                |> GroupDoc.sortProjects

        filterTodoForProject project =
            tcg.todoList
                |> List.filter (Data.TodoDoc.hasProject project)
    in
    projects .|> initProjectNode filterTodoForProject


initContextRoot getTodoList findContextById context =
    context
        |> initContextNode getTodoList
        |> (\tcg -> ContextRoot tcg (createProjectSubGroups findContextById tcg))


createContextSubGroups findContextById tcg =
    let
        contexts =
            tcg.todoList
                .|> Data.TodoDoc.getContextId
                |> List.unique
                .|> findContextById
                |> List.filterMap identity
                |> GroupDoc.sortContexts

        filterTodoForContext context =
            tcg.todoList
                |> List.filter (Data.TodoDoc.contextFilter context)
    in
    contexts .|> initContextNode filterTodoForContext


initProjectRoot getTodoList findProjectById project =
    project
        |> initProjectNode getTodoList
        |> (\tcg -> ProjectRoot tcg (createContextSubGroups findProjectById tcg))


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
        ContextRoot node nodeList ->
            Entity.createContextEntity node.context
                :: (nodeList
                        |> List.concatMap
                            (\node ->
                                Entity.createProjectEntity node.project
                                    :: (node.todoList .|> Entity.TodoEntity)
                            )
                   )

        ProjectRoot node nodeList ->
            Entity.createProjectEntity node.project
                :: (nodeList
                        |> List.concatMap
                            (\node ->
                                Entity.createContextEntity node.context
                                    :: (node.todoList .|> Entity.TodoEntity)
                            )
                   )

        SingleNode node ->
            getNodeEntityList node

        RootNode node nodeList ->
            let
                getNodeEntityList node =
                    case node of
                        Node (GroupDocEntityTitle gdEntity) todoList _ ->
                            [ Entity.GroupDocEntityW gdEntity ]

                        Node (StringTitle _) todoList _ ->
                            todoList .|> Entity.TodoEntity
            in
            getNodeEntityList node ++ (nodeList |> List.concatMap getNodeEntityList)

        Forest nodeList ->
            nodeList |> List.concatMap getNodeEntityList


createRootLeafNodeWithStringTitle stringTitle todoList totalCount =
    SingleNode (Node (StringTitle stringTitle) todoList totalCount)


createGroupDocEntityNode gdEntity todoList totalCount =
    Node (GroupDocEntityTitle gdEntity) todoList totalCount


createRootGroupDocEntityNode gdEntity todoList totalCount =
    Node (GroupDocEntityTitle gdEntity) todoList totalCount


createForest : List Node -> Tree
createForest =
    Forest
