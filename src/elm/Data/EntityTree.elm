module Data.EntityTree exposing (..)

import Context
import Entity
import Entity.Types exposing (..)
import List.Extra as List
import Maybe.Extra as Maybe
import Project
import Todo
import Toolkit.Helpers exposing (..)
import Toolkit.Operators exposing (..)
import Types.GroupDoc exposing (GroupDoc)
import Types.Todo exposing (..)
import X.Function exposing (..)
import X.Function.Infix exposing (..)


type alias ContextNode =
    { context : Context.Model
    , todoList : List TodoDoc
    }


type alias ProjectNode =
    { project : Project.Model
    , todoList : List TodoDoc
    }


type Title
    = GroupEntityTitle GroupEntityType
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


createProjectSubGroups findProjectById tcg =
    let
        projects =
            tcg.todoList
                .|> Todo.getProjectId
                |> List.unique
                .|> findProjectById
                |> List.filterMap identity
                |> Project.sort

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
                |> Context.sort

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
            Entity.fromContext node.context
                :: flatten (ProjectForest nodeList)

        ProjectRoot node nodeList ->
            Entity.fromProject node.project
                :: flatten (ContextForest nodeList)

        ContextForest nodeList ->
            nodeList
                |> List.concatMap
                    (\node -> Entity.fromContext node.context :: (node.todoList .|> Entity.Types.TodoEntity))

        ProjectForest groupList ->
            groupList
                |> List.concatMap
                    (\g ->
                        Entity.fromProject g.project
                            :: (g.todoList .|> Entity.Types.TodoEntity)
                    )

        TodoForest title todoList ->
            todoList .|> Entity.Types.TodoEntity

        Root node ->
            []

        Forest list node ->
            []


initTodoForest stringTitle todoList =
    Root (Node (StringTitle stringTitle) todoList)
