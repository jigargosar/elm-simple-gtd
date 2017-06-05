module Entity exposing (..)

import Context
import Document
import Ext.List as List
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
    | OnFocusIn
    | ToggleSelected


getId entity =
    case entity of
        TodoEntity doc ->
            Document.getId doc

        ProjectEntity doc ->
            Document.getId doc

        ContextEntity doc ->
            Document.getId doc


equalById e1 e2 =
    let
        eq =
            Document.equalById
    in
        case ( e1, e2 ) of
            ( ProjectEntity m1, ProjectEntity m2 ) ->
                eq m1 m2

            ( ContextEntity m1, ContextEntity m2 ) ->
                eq m1 m2

            ( TodoEntity m1, TodoEntity m2 ) ->
                eq m1 m2

            _ ->
                False


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
    | SingleProject TodoProjectGroup (List TodoContextGroup)
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
                |> Project.sort

        filterTodoForProject project =
            tcg.list
                |> List.filter (Todo.projectFilter project)
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
            tcg.list
                .|> Todo.getContextId
                |> List.unique
                .|> findContextById
                |> List.filterMap identity
                |> Context.sort

        filterTodoForContext context =
            tcg.list
                |> List.filter (Todo.contextFilter context)
    in
        contexts .|> createContextTodoGroup filterTodoForContext


createGroupingForProject getTodoList findProjectById project =
    project
        |> createProjectTodoGroup getTodoList
        |> (\tcg -> SingleProject tcg (createContextSubGroups findProjectById tcg))


flattenGrouping : Grouping -> List Entity
flattenGrouping grouping =
    case grouping of
        SingleContext cg pgList ->
            (ContextEntity cg.context)
                :: flattenGrouping (MultiProject pgList)

        SingleProject pg cgList ->
            (ProjectEntity pg.project)
                :: flattenGrouping (MultiContext cgList)

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


findEntityByOffsetIn offsetIndex entityList fromEntity =
    entityList
        |> List.findIndex (equalById fromEntity)
        ?= 0
        |> add offsetIndex
        |> List.clampIndexIn entityList
        |> List.atIndexIn entityList
        |> Maybe.orElse (List.head entityList)
