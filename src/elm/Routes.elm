module Routes exposing (..)

import Entity.Types exposing (EntityListViewType(..))
import Maybe.Extra
import Model.ViewType
import Msg exposing (..)
import Navigation exposing (Location)
import RouteUrl.Builder exposing (..)
import RouteUrl exposing (UrlChange)
import ReturnTypes exposing (..)
import Types exposing (..)
import ViewType exposing (ViewType(EntityListView, SyncView))
import X.Function.Infix exposing (..)
import X.List


delta2builder : AppModel -> AppModel -> Maybe Builder
delta2builder previous current =
    builder
        |> replacePath (getPathFromModel current)
        |> Just


getPathFromModel model =
    case Model.ViewType.getMainViewType model of
        EntityListView viewType ->
            getPathFromViewType viewType

        SyncView ->
            [ "custom-sync" ]


delta2hash : AppModel -> AppModel -> Maybe UrlChange
delta2hash =
    delta2builder >>> Maybe.map toHashChange


builder2messages : Builder -> List AppMsg
builder2messages builder =
    routeUrlBuilderToMaybeListViewType builder
        |> Maybe.Extra.unpack
            (\_ ->
                case path builder of
                    "custom-sync" :: [] ->
                        [ Msg.switchToView SyncView ]

                    _ ->
                        -- If nothing provided for this part of the URL, return empty list
                        [ Msg.switchToView defaultView ]
            )
            (Msg.onSetEntityListView >> X.List.singleton)


hash2messages : Location -> List AppMsg
hash2messages location =
    builder2messages (fromHash location.href)


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
