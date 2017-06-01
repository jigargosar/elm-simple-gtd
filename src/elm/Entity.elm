module Entity exposing (..)

import Context
import Document
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


type alias TodoGroup =
    { groupEntity : GroupEntity
    , list : TodoList
    }


type Grouping
    = Single TodoGroup
    | Multi (List TodoGroup)


createContextTodoGroup getTodoList context =
    { groupEntity = ContextGroup context
    , list = getTodoList context
    }


createProjectTodoGroup getTodoList project =
    { groupEntity = ProjectGroup project
    , list = getTodoList project
    }


createGroupingForContexts getTodoList contexts =
    contexts .|> createContextTodoGroup getTodoList |> Multi


createGroupingForProjects getTodoList projects =
    projects .|> createProjectTodoGroup getTodoList |> Multi



{- | Flat TodoList -}
