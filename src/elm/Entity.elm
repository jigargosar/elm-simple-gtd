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
    | BinView
    | DoneView


type Action
    = StartEditing
    | ToggleDeleted
    | ToggleArchived
    | Save
    | NameChanged String
    | OnFocusIn
    | ToggleSelected
    | Goto


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

        BinView ->
            [ "bin" ]

        DoneView ->
            [ "done" ]


getTodoGotoGroupView todo prevView =
    let
        contextView =
            Todo.getContextId todo |> ContextView

        projectView =
            Todo.getProjectId todo |> ProjectView
    in
        case prevView of
            ProjectsView ->
                contextView

            ProjectView _ ->
                contextView

            ContextsView ->
                projectView

            ContextView _ ->
                projectView

            BinView ->
                ContextsView

            DoneView ->
                ContextsView


getGotoEntityViewType : Maybe ListViewType -> Entity -> ListViewType
getGotoEntityViewType maybePrevView entity =
    case entity of
        ContextEntity model ->
            Document.getId model |> ContextView

        ProjectEntity model ->
            Document.getId model |> ProjectView

        TodoEntity model ->
            maybePrevView ?|> getTodoGotoGroupView model ?= (Todo.getContextId model |> ContextView)


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
                            :: (g.todoList .|> TodoEntity)
                    )

        MultiProject groupList ->
            groupList
                |> List.concatMap
                    (\g ->
                        (ProjectEntity g.project)
                            :: (g.todoList .|> TodoEntity)
                    )

        FlatTodoList title todoList ->
            todoList .|> TodoEntity


findEntityByOffsetIn offsetIndex entityList fromEntity =
    entityList
        |> List.findIndex (equalById fromEntity)
        ?= 0
        |> add offsetIndex
        |> List.clampIndexIn entityList
        |> List.atIndexIn entityList
        |> Maybe.orElse (List.head entityList)
