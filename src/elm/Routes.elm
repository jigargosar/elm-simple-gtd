module Routes exposing (..)

import Entity.Types exposing (..)
import Maybe.Extra
import Page exposing (Page(CustomSyncSettingsPage, EntityListPage))
import Pages.EntityList exposing (..)
import RouteUrl.Builder
import X.Function.Infix exposing (..)
import X.List


--delta2builder : AppModel -> AppModel -> Maybe Builder


delta2builder previous current =
    RouteUrl.Builder.builder
        |> RouteUrl.Builder.replacePath (getPathFromModel current)
        |> Just


getPathFromModel model =
    case Page.getPage model of
        EntityListPage page ->
            getPathFromPage page

        CustomSyncSettingsPage ->
            [ "custom-sync" ]



--delta2hash : AppModel -> AppModel -> Maybe UrlChange


delta2hash =
    delta2builder >>> Maybe.map RouteUrl.Builder.toHashChange



--builder2messages : Builder -> List AppMsg


builder2messages config builder =
    routeUrlBuilderToMaybeListPage builder
        |> Maybe.Extra.unpack
            (\_ ->
                case RouteUrl.Builder.path builder of
                    "custom-sync" :: [] ->
                        [ config.gotoPage CustomSyncSettingsPage ]

                    _ ->
                        -- If nothing provided for this part of the URL, return empty list
                        [ config.gotoPage Page.initialPage ]
            )
            (config.switchToEntityListPageMsg >> X.List.singleton)



--hash2messages : Location -> List AppMsg


hash2messages config location =
    builder2messages config (RouteUrl.Builder.fromHash location.href)



--routeUrlBuilderToMaybeListPage : RouteUrl.Builder.Builder -> Maybe EntityListPage


routeUrlBuilderToMaybeListPage builder =
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
            ContextView "" |> Just

        "context" :: id :: [] ->
            ContextView id |> Just

        "project" :: "NotAssigned" :: [] ->
            ProjectView "" |> Just

        "project" :: id :: [] ->
            ProjectView id |> Just

        _ ->
            Nothing


getPathFromPage page =
    case page of
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
