module Entity exposing (..)

import Context
import Document
import Entity.Types exposing (EntityType(..), GroupEntityType(..), EntityListViewType(..))
import X.List as List
import RouteUrl.Builder
import Toolkit.Operators exposing (..)
import X.Function exposing (..)
import List.Extra as List
import Maybe.Extra as Maybe
import Project
import Todo


type alias GroupEntity =
    Entity.Types.GroupEntityType


type alias Entity =
    Entity.Types.EntityType


fromContext =
    ContextEntity >> GroupEntity


fromProject =
    ProjectEntity >> GroupEntity


fromTodo =
    TodoEntity


initProjectGroup =
    ProjectEntity


initContextGroup =
    ContextEntity


type alias Msg =
    Entity.Types.Msg


getId entity =
    case entity of
        TodoEntity model ->
            Document.getId model

        GroupEntity group ->
            case group of
                ProjectEntity model ->
                    Document.getId model

                ContextEntity model ->
                    Document.getId model


equalById e1 e2 =
    let
        eq =
            Document.equalById
    in
        case ( e1, e2 ) of
            ( GroupEntity g1, GroupEntity g2 ) ->
                case ( g1, g2 ) of
                    ( ProjectEntity m1, ProjectEntity m2 ) ->
                        eq m1 m2

                    ( ContextEntity m1, ContextEntity m2 ) ->
                        eq m1 m2

                    _ ->
                        False

            ( TodoEntity m1, TodoEntity m2 ) ->
                eq m1 m2

            _ ->
                False


defaultListView =
    ContextsView


routeUrlBuilderToMaybeListViewType : RouteUrl.Builder.Builder -> Maybe EntityListViewType
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

        "recent" :: [] ->
            RecentView |> Just

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

        RecentView ->
            [ "recent" ]


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

            RecentView ->
                ContextsView


toViewType : Maybe EntityListViewType -> Entity -> EntityListViewType
toViewType maybePrevView entity =
    case entity of
        GroupEntity group ->
            case group of
                ContextEntity model ->
                    Document.getId model |> ContextView

                ProjectEntity model ->
                    Document.getId model |> ProjectView

        TodoEntity model ->
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
