module Entity exposing (..)

import Document
import Document.Types exposing (getDocId)
import Entity.Types exposing (Entity(..), EntityId(ContextId, ProjectId, TodoId), EntityListViewType(..), GroupEntityType(..))
import X.List as List
import RouteUrl.Builder
import Toolkit.Operators exposing (..)
import X.Function exposing (..)
import List.Extra as List
import Maybe.Extra as Maybe
import Todo
import Tuple2


type alias GroupEntity =
    Entity.Types.GroupEntityType


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
    Entity.Types.EntityUpdateMsg


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


toEntityId entity =
    case entity of
        TodoEntity m ->
            TodoId (getDocId m)

        GroupEntity ge ->
            case ge of
                ProjectEntity m ->
                    ProjectId (getDocId m)

                ContextEntity m ->
                    ContextId (getDocId m)


equalById e1 e2 =
    ( e1, e2 )
        |> Tuple2.mapBoth toEntityId
        |> uncurry equals


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
