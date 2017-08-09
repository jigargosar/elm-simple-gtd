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
    | ContextForest (List ContextNode)
    | ProjectForest (List ProjectNode)
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


initContextForest getTodoList contexts =
    contexts .|> initContextNode getTodoList |> ContextForest


initGroupDocForest groupDocType getTodoList groupDocs =
    let
        initContextNode context =
            { context = context
            , todoList = getTodoList (Document.getId context)
            }

        initProjectNode project =
            { project = project
            , todoList = getTodoList (Document.getId project)
            }
    in
    case groupDocType of
        ContextGroupDocType ->
            groupDocs .|> initContextNode |> ContextForest

        ProjectGroupDocType ->
            groupDocs .|> initProjectNode |> ProjectForest


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


initProjectForest getTodoList projects =
    projects .|> initProjectNode getTodoList |> ProjectForest


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
                :: flatten (ProjectForest nodeList)

        ProjectRoot node nodeList ->
            Entity.createProjectEntity node.project
                :: flatten (ContextForest nodeList)

        ContextForest nodeList ->
            nodeList
                |> List.concatMap
                    (\node -> Entity.createContextEntity node.context :: (node.todoList .|> Entity.TodoEntity))

        ProjectForest groupList ->
            groupList
                |> List.concatMap
                    (\g ->
                        Entity.createProjectEntity g.project
                            :: (g.todoList .|> Entity.TodoEntity)
                    )

        Root node _ ->
            getNodeEntityList node

        Forest nodeList ->
            nodeList |> List.concatMap getNodeEntityList


createRootWithStringTitle stringTitle todoList totalCount =
    Root (Node (StringTitle stringTitle) todoList) totalCount
