module Pages.EntityList exposing (..)

import RouteUrl.Builder
import Types.Document exposing (..)


type Old_EntityListPageModel
    = ContextsView
    | ContextView DocId
    | ProjectsView
    | ProjectView DocId
    | BinView
    | DoneView
    | RecentView


initialEntityListPageModel =
    ContextsView


routeUrlBuilderToMaybeEntityListPageModel :
    RouteUrl.Builder.Builder
    -> Maybe Old_EntityListPageModel
routeUrlBuilderToMaybeEntityListPageModel builder =
    case RouteUrl.Builder.path builder of
        "contexts" :: [] ->
            ContextsView |> Just

        "projects" :: [] ->
            ProjectsView |> Just

        "bin" :: [] ->
            BinView |> Just

        "done" :: [] ->
            DoneView |> Just

        "recent" :: [] ->
            RecentView |> Just

        "Inbox" :: [] ->
            ContextView "" |> Just

        "context" :: id :: [] ->
            ContextView id |> Just

        "project" :: "NotAssigned" :: [] ->
            ProjectView "" |> Just

        "project" :: id :: [] ->
            ProjectView id |> Just

        _ ->
            Nothing


getPathFromEntityListPageModel page =
    case page of
        ContextsView ->
            [ "contexts" ]

        ProjectsView ->
            [ "projects" ]

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
