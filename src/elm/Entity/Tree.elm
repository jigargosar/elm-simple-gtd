module Entity.Tree exposing (..)

import Context
import Entity
import GroupDoc
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


type alias GroupNode =
    { groupDoc : GroupDoc.Model
    , todoList : TodoNodeList
    , groupEntity : Entity.GroupEntity
    }


type alias GroupNodeList =
    List GroupNode


type alias TitleNode =
    String


type Tree
    = ContextRoot GroupNode GroupNodeList
    | ProjectRoot GroupNode GroupNodeList
    | ContextForest GroupNodeList
    | ProjectForest GroupNodeList
    | TodoForest TitleNode TodoNodeList


initGroupNode getTodoList groupDoc =
    { groupDoc = groupDoc
    , todoList = getTodoList groupDoc
    , groupEntity = Entity.initContextGroupEntity groupDoc
    }


initGroupDocNodeList getTodoList groupDocList =
    groupDocList .|> initGroupNode getTodoList


initContextForest =
    initGroupDocNodeList >>> ContextForest


initProjectForest =
    initGroupDocNodeList >>> ProjectForest


initContextRoot getTodoList findContextById context =
    initGroupNode getTodoList context
        |> (\groupNode -> ContextRoot groupNode (createProjectSubGroups findContextById groupNode))


createProjectSubGroups findProjectById node =
    let
        projects =
            node.todoList
                .|> Todo.getProjectId
                |> List.unique
                .|> findProjectById
                |> List.filterMap identity
                |> Project.sort

        filterTodoForProject project =
            node.todoList
                |> List.filter (Todo.hasProject project)
    in
        projects .|> initGroupNode filterTodoForProject


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
        contexts .|> initGroupNode filterTodoForContext


initProjectRoot getTodoList findProjectById project =
    project
        |> initGroupNode getTodoList
        |> (\tcg -> ProjectRoot tcg (createContextSubGroups findProjectById tcg))


initTodoForest : String -> TodoNodeList -> Tree
initTodoForest =
    TodoForest


flatten : Tree -> List Entity.Entity
flatten tree =
    case tree of
        ContextRoot node nodeList ->
            Entity.fromGroupEntity node.groupEntity
                :: flatten (ProjectForest nodeList)

        ProjectRoot node nodeList ->
            Entity.fromGroupEntity node.groupEntity
                :: flatten (ContextForest nodeList)

        ContextForest nodeList ->
            nodeList
                |> List.concatMap
                    (\node ->
                        Entity.fromGroupEntity node.groupEntity
                            :: (node.todoList .|> Entity.fromTask)
                    )

        ProjectForest groupList ->
            groupList
                |> List.concatMap
                    (\node ->
                        Entity.fromGroupEntity node.groupEntity
                            :: (node.todoList .|> Entity.fromTask)
                    )

        TodoForest title todoList ->
            todoList .|> Entity.fromTask
