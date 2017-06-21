module Entity exposing (..)

import Context
import Document
import Ext.List as List
import RouteUrl.Builder
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


type GroupEntity
    = Project Project.Model
    | Context Context.Model


type Entity
    = Group GroupEntity
    | Task Todo.Model


fromContext =
    Context >> Group


fromProject =
    Project >> Group


fromTask =
    Task


initProjectGroupEntity =
    Project


initContextGroupEntity =
    Context


fromGroupEntity =
    Group


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
        Task model ->
            Document.getId model

        Group group ->
            case group of
                Project model ->
                    Document.getId model

                Context model ->
                    Document.getId model


equalById e1 e2 =
    let
        eq =
            Document.equalById
    in
        case ( e1, e2 ) of
            ( Group g1, Group g2 ) ->
                case ( g1, g2 ) of
                    ( Project m1, Project m2 ) ->
                        eq m1 m2

                    ( Context m1, Context m2 ) ->
                        eq m1 m2

                    _ ->
                        False

            ( Task m1, Task m2 ) ->
                eq m1 m2

            _ ->
                False


defaultListView =
    ContextsView


routeUrlBuilderToMaybeListViewType : RouteUrl.Builder.Builder -> Maybe ListViewType
routeUrlBuilderToMaybeListViewType builder =
    case RouteUrl.Builder.path builder of
        "lists" :: "contexts" :: [] ->
            ContextsView |> Just

        "lists" :: "projects" :: [] ->
            ProjectsView |> Just

        "bin" :: [] ->
            BinView |> Just

        "done" :: [] ->
            DoneView |> Just

        "Inbox" :: [] ->
            (ContextView "") |> Just

        "context" :: id :: [] ->
            (ContextView id) |> Just

        "project" :: "NotAssigned" :: [] ->
            (ProjectView "") |> Just

        "project" :: id :: [] ->
            (ProjectView id) |> Just

        _ ->
            Nothing


getPathFromViewType viewType =
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


toViewType : Maybe ListViewType -> Entity -> ListViewType
toViewType maybePrevView entity =
    case entity of
        Group group ->
            case group of
                Context model ->
                    Document.getId model |> ContextView

                Project model ->
                    Document.getId model |> ProjectView

        Task model ->
            maybePrevView
                ?|> getTodoGotoGroupView model
                ?= (Todo.getContextId model |> ContextView)


findEntityByOffsetIn offsetIndex entityList fromEntity =
    entityList
        |> List.findIndex (equalById fromEntity)
        ?= 0
        |> add offsetIndex
        |> List.clampIndexIn entityList
        |> List.atIndexIn entityList
        |> Maybe.orElse (List.head entityList)
