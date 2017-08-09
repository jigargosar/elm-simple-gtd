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


type Title
    = GroupDocEntityTitle GroupDocEntity
    | StringTitle String


type Node
    = Node Title (List TodoDoc)


type Tree
    = ContextRoot ContextNode (List ProjectNode)
    | ProjectRoot ProjectNode (List ContextNode)
    | Root Node Int
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
                Node (GroupDocEntityTitle gdEntity) todoList ->
                    Entity.GroupDocEntityW gdEntity :: (todoList .|> Entity.TodoEntity)

                Node (StringTitle _) todoList ->
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

        Root node _ ->
            getNodeEntityList node

        Forest nodeList ->
            nodeList |> List.concatMap getNodeEntityList


createRootWithStringTitle stringTitle todoList totalCount =
    Root (Node (StringTitle stringTitle) todoList) totalCount


createGroupDocEntityNode gdEntity todoList =
    Node (GroupDocEntityTitle gdEntity) todoList


createForest : List Node -> Tree
createForest =
    Forest
