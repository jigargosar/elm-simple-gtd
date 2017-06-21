module Entity.Tree exposing (..)

import Context
import Entity
import Todo
import Toolkit.Helpers exposing (..)
import Toolkit.Operators exposing (..)
import Ext.Function exposing (..)
import Ext.Function.Infix exposing (..)
import List.Extra as List
import Maybe.Extra as Maybe
import Project


type alias TodoList =
    List Todo.Model


type alias ContextNode =
    { context : Context.Model
    , todoList : TodoList
    }


type alias ProjectNode =
    { project : Project.Model
    , todoList : TodoList
    }


type Tree
    = ContextRoot ContextNode (List ProjectNode)
    | ProjectRoot ProjectNode (List ContextNode)
    | ContextForest (List ContextNode)
    | ProjectForest (List ProjectNode)
    | TodoForest String TodoList


createContextTodoGroup getTodoList context =
    { context = context
    , todoList = getTodoList context
    }


createProjectTodoGroup getTodoList project =
    { project = project
    , todoList = getTodoList project
    }


createGroupingForContexts getTodoList contexts =
    contexts .|> createContextTodoGroup getTodoList |> ContextForest


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
        projects .|> createProjectTodoGroup filterTodoForProject


createGroupingForContext getTodoList findContextById context =
    context
        |> createContextTodoGroup getTodoList
        |> (\tcg -> ContextRoot tcg (createProjectSubGroups findContextById tcg))


createGroupingForProjects getTodoList projects =
    projects .|> createProjectTodoGroup getTodoList |> ProjectForest


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
        contexts .|> createContextTodoGroup filterTodoForContext


createGroupingForProject getTodoList findProjectById project =
    project
        |> createProjectTodoGroup getTodoList
        |> (\tcg -> ProjectRoot tcg (createContextSubGroups findProjectById tcg))


createGroupingForTodoList : String -> TodoList -> Tree
createGroupingForTodoList =
    TodoForest


flattenGrouping : Tree -> List Entity.Entity
flattenGrouping grouping =
    case grouping of
        ContextRoot cg pgList ->
            Entity.fromContext cg.context
                :: flattenGrouping (ProjectForest pgList)

        ProjectRoot pg cgList ->
            Entity.fromProject pg.project
                :: flattenGrouping (ContextForest cgList)

        ContextForest groupList ->
            groupList
                |> List.concatMap
                    (\g ->
                        Entity.fromContext g.context
                            :: (g.todoList .|> Entity.Task)
                    )

        ProjectForest groupList ->
            groupList
                |> List.concatMap
                    (\g ->
                        Entity.fromProject g.project
                            :: (g.todoList .|> Entity.Task)
                    )

        TodoForest title todoList ->
            todoList .|> Entity.Task