module Data.EntityTree exposing (..)

import Document
import Entity exposing (..)
import GroupDoc
import List.Extra as List
import Todo
import Toolkit.Operators exposing (..)
import Types.GroupDoc exposing (..)
import Types.Todo exposing (..)


type alias ContextNode =
    { context : ContextDoc
    , todoList : List TodoDoc
    }


type alias ProjectNode =
    { project : ProjectDoc
    , todoList : List TodoDoc
    }


type Title
    = GroupEntityTitle GroupDocEntity
    | StringTitle String


type Node
    = Node Title (List TodoDoc)


type Tree
    = ContextRoot ContextNode (List ProjectNode)
    | ProjectRoot ProjectNode (List ContextNode)
    | ContextForest (List ContextNode)
    | ProjectForest (List ProjectNode)
    | TodoForest String (List TodoDoc)
    | Root Node
    | Forest List Node


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
                .|> Todo.getProjectId
                |> List.unique
                .|> findProjectById
                |> List.filterMap identity
                |> GroupDoc.sortProjects

        filterTodoForProject project =
            tcg.todoList
                |> List.filter (Todo.hasProject project)
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
                .|> Todo.getContextId
                |> List.unique
                .|> findContextById
                |> List.filterMap identity
                |> GroupDoc.sortContexts

        filterTodoForContext context =
            tcg.todoList
                |> List.filter (Todo.contextFilter context)
    in
    contexts .|> initContextNode filterTodoForContext


initProjectRoot getTodoList findProjectById project =
    project
        |> initProjectNode getTodoList
        |> (\tcg -> ProjectRoot tcg (createContextSubGroups findProjectById tcg))


flatten : Tree -> List Entity
flatten tree =
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

        TodoForest title todoList ->
            todoList .|> Entity.TodoEntity

        Root node ->
            case node of
                Node (StringTitle title) todoList ->
                    todoList .|> Entity.TodoEntity

                _ ->
                    []

        Forest list node ->
            []


initTodoForest stringTitle todoList =
    Root (Node (StringTitle stringTitle) todoList)
