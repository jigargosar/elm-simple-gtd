module Entity exposing (..)

import Context
import Document
import Set
import Time exposing (Time)
import Toolkit.Helpers exposing (..)
import Toolkit.Operators exposing (..)
import Ext.Function exposing (..)
import Ext.Function.Infix exposing (..)
import List.Extra as List
import Maybe.Extra as Maybe
import Project
import Todo


type Entity
    = ProjectEntity Project.Model
    | ContextEntity Context.Model
    | TodoEntity Todo.Model


type ListViewType
    = ContextsView
    | ContextView Document.Id
    | ProjectsView
    | ProjectView Document.Id


type Action
    = StartEditing
    | ToggleDeleted
    | Save
    | NameChanged String
    | SetFocused
    | SetBlurred
    | SetFocusedIn
    | ToggleSelected


defaultListView =
    ContextsView


routes viewType =
    case viewType of
        ContextsView ->
            [ "lists", "contexts" ]

        ProjectsView ->
            [ "lists", "projects" ]

        ProjectView id ->
            if String.isEmpty id then
                [ "project", "NotAssigned" ]
            else
                [ "project", id ]

        ContextView id ->
            if String.isEmpty id then
                [ "Inbox" ]
            else
                [ "context", id ]


type GroupEntity
    = ProjectGroup Project.Model
    | ContextGroup Context.Model



{- | TimeGroup Time -}


type alias TodoList =
    List Todo.Model


type alias TodoContextGroup =
    { context : Context.Model
    , list : TodoList
    }


type alias TodoProjectGroup =
    { project : Project.Model
    , list : TodoList
    }


type Grouping
    = SingleContext TodoContextGroup (List TodoProjectGroup)
    | SingleProject TodoProjectGroup (List TodoProjectGroup)
    | MultiContext (List TodoContextGroup)
    | MultiProject (List TodoProjectGroup)


createContextTodoGroup getTodoList context =
    { context = context
    , list = getTodoList context
    }


createProjectTodoGroup getTodoList project =
    { project = project
    , list = getTodoList project
    }


createGroupingForContexts getTodoList contexts =
    contexts .|> createContextTodoGroup getTodoList |> MultiContext


createProjectSubGroups findProjectById tcg =
    let
        projects =
            tcg.list
                .|> Todo.getProjectId
                |> List.unique
                .|> findProjectById
                |> List.filterMap identity

        filterTodoForProject project =
            tcg.list
                |> List.filter (Todo.projectFilter project)
    in
        projects .|> createProjectTodoGroup filterTodoForProject


createGroupingForContext getTodoList findProjectById context =
    context
        |> createContextTodoGroup getTodoList
        |> (\tcg -> SingleContext tcg (createProjectSubGroups findProjectById tcg))


createGroupingForProjects getTodoList projects =
    projects .|> createProjectTodoGroup getTodoList |> MultiProject


createContextSubGroups findContextById tcg =
    let
        contexts =
            tcg.list
                .|> Todo.getContextId
                |> List.unique
                .|> findContextById
                |> List.filterMap identity

        filterTodoForContext context =
            tcg.list
                |> List.filter (Todo.contextFilter context)
    in
        contexts .|> createContextTodoGroup filterTodoForContext


createGroupingForProject getTodoList findProjectById project =
    project
        |> createProjectTodoGroup getTodoList
        |> (\tcg -> SingleProject tcg (createProjectSubGroups findProjectById tcg))


flattenGrouping : Grouping -> List Entity
flattenGrouping grouping =
    case grouping of
        SingleContext cg pgList ->
            (ContextEntity cg.context)
                :: flattenGrouping (MultiProject pgList)

        SingleProject pg cgList ->
            (ProjectEntity pg.project)
                :: flattenGrouping (MultiProject cgList)

        MultiContext groupList ->
            groupList
                |> List.concatMap
                    (\g ->
                        (ContextEntity g.context)
                            :: (g.list .|> TodoEntity)
                    )

        MultiProject groupList ->
            groupList
                |> List.concatMap
                    (\g ->
                        (ProjectEntity g.project)
                            :: (g.list .|> TodoEntity)
                    )
