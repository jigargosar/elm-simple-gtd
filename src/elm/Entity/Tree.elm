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


type alias ContextGroup =
    { context : Context.Model
    , todoList : TodoList
    }


type alias ProjectGroup =
    { project : Project.Model
    , todoList : TodoList
    }


type Grouping
    = SingleContext ContextGroup (List ProjectGroup)
    | SingleProject ProjectGroup (List ContextGroup)
    | MultiContext (List ContextGroup)
    | MultiProject (List ProjectGroup)
    | FlatTodoList String TodoList


createContextTodoGroup getTodoList context =
    { context = context
    , todoList = getTodoList context
    }


createProjectTodoGroup getTodoList project =
    { project = project
    , todoList = getTodoList project
    }


createGroupingForContexts getTodoList contexts =
    contexts .|> createContextTodoGroup getTodoList |> MultiContext


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
        |> (\tcg -> SingleContext tcg (createProjectSubGroups findContextById tcg))


createGroupingForProjects getTodoList projects =
    projects .|> createProjectTodoGroup getTodoList |> MultiProject


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
        |> (\tcg -> SingleProject tcg (createContextSubGroups findProjectById tcg))


createGroupingForTodoList : String -> TodoList -> Grouping
createGroupingForTodoList =
    FlatTodoList


flattenGrouping : Grouping -> List Entity.Entity
flattenGrouping grouping =
    case grouping of
        SingleContext cg pgList ->
            Entity.fromContext cg.context
                :: flattenGrouping (MultiProject pgList)

        SingleProject pg cgList ->
            Entity.fromProject pg.project
                :: flattenGrouping (MultiContext cgList)

        MultiContext groupList ->
            groupList
                |> List.concatMap
                    (\g ->
                        Entity.fromContext g.context
                            :: (g.todoList .|> Entity.Task)
                    )

        MultiProject groupList ->
            groupList
                |> List.concatMap
                    (\g ->
                        Entity.fromProject g.project
                            :: (g.todoList .|> Entity.Task)
                    )

        FlatTodoList title todoList ->
            todoList .|> Entity.Task
