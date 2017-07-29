module Routes exposing (..)

import Page exposing (..)
import Pages.EntityList exposing (..)
import RouteUrl.Builder
import Toolkit.Operators exposing (..)
import X.Function.Infix exposing (..)
import X.List


--delta2hash : AppModel -> AppModel -> Maybe UrlChange


delta2hash =
    let
        delta2builder previousModel currentModel =
            RouteUrl.Builder.builder
                |> RouteUrl.Builder.replacePath (getPathFromModel currentModel)
                |> Just
    in
    delta2builder >>> Maybe.map RouteUrl.Builder.toHashChange


getPathFromModel model =
    case Page.getPage model of
        EntityListPage page ->
            getPathFromEntityListPageModel page

        CustomSyncSettingsPage ->
            [ "custom-sync" ]



--hash2messages : Location -> List AppMsg


hash2messages config location =
    builder2messages config (RouteUrl.Builder.fromHash location.href)



--builder2messages : Builder -> List AppMsg


builder2messages config builder =
    case RouteUrl.Builder.path builder of
        "custom-sync" :: [] ->
            [ config.gotoPageMsg CustomSyncSettingsPage ]

        _ ->
            routeUrlBuilderToMaybeEntityListPageModel builder
                ?|> (config.switchToEntityListPageMsg >> X.List.singleton)
                ?= [ config.gotoPageMsg Page.initialPage ]
