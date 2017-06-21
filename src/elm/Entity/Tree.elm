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


type alias TodoNode =
    Todo.Model


type alias TodoNodeList =
    List Todo.Model


type alias ContextNode =
    { context : Context.Model
    , todoList : TodoNodeList
    }


type alias ProjectNode =
    { project : Project.Model
    , todoList : TodoNodeList
    }


type alias ProjectNodeList =
    List ProjectNode


type alias ContextNodeList =
    List ContextNode


type alias TitleNode =
    String


type Tree
    = ContextRoot ContextNode ProjectNodeList
    | ProjectRoot ProjectNode ContextNodeList
    | ContextForest ContextNodeList
    | ProjectForest ProjectNodeList
    | TodoForest TitleNode TodoNodeList


initContextNode getTodoList context =
    { context = context
    , todoList = getTodoList context
    }


initProjectNode getTodoList project =
    { project = project
    , todoList = getTodoList project
    }


createGroupingForContexts getTodoList contexts =
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


createGroupingForContext getTodoList findContextById context =
    context
        |> initContextNode getTodoList
        |> (\tcg -> ContextRoot tcg (createProjectSubGroups findContextById tcg))


createGroupingForProjects getTodoList projects =
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


createGroupingForProject getTodoList findProjectById project =
    project
        |> initProjectNode getTodoList
        |> (\tcg -> ProjectRoot tcg (createContextSubGroups findProjectById tcg))


createGroupingForTodoList : String -> TodoNodeList -> Tree
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
