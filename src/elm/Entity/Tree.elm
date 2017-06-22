module Entity.Tree exposing (..)

import Context
import Entity
import Todo
import Toolkit.Helpers exposing (..)
import Toolkit.Operators exposing (..)
import X.Function exposing (..)
import X.Function.Infix exposing (..)
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
    , groupEntity : Entity.GroupEntity
    }


type alias ProjectNode =
    { project : Project.Model
    , todoList : TodoNodeList
    , groupEntity : Entity.GroupEntity
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
    , groupEntity = Entity.initContextGroup context
    }


initProjectNode getTodoList project =
    { project = project
    , todoList = getTodoList project
    , groupEntity = Entity.initProjectGroup project
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


initTodoForest : String -> TodoNodeList -> Tree
initTodoForest =
    TodoForest


flatten : Tree -> List Entity.Entity
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
                    (\node -> Entity.fromContext node.context :: (node.todoList .|> Entity.Task))

        ProjectForest groupList ->
            groupList
                |> List.concatMap
                    (\g ->
                        Entity.fromProject g.project
                            :: (g.todoList .|> Entity.Task)
                    )

        TodoForest title todoList ->
            todoList .|> Entity.Task
