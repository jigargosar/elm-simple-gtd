module Page exposing (..)

import Pages.EntityList exposing (..)
import RouteUrl.Builder
import Toolkit.Helpers exposing (..)
import Toolkit.Operators exposing (..)
import X.Function.Infix exposing (..)
import X.List


type Page
    = EntityListPage EntityListPageModel
    | CustomSyncSettingsPage


type PageMsg
    = PageMsg_SetPage Page
    | PageMsg_SetEntityListPage EntityListPageModel
    | PageMsg_NavigateToPath (List String)


maybeGetEntityListPage model =
    case getPage__ model of
        EntityListPage pageModel ->
            Just pageModel

        _ ->
            Nothing


getPage__ =
    .page


initialPage =
    EntityListPage Pages.EntityList.initialEntityListPageModel


delta2hash =
    let
        delta2builder previousModel currentModel =
            RouteUrl.Builder.builder
                |> RouteUrl.Builder.replacePath (getPathFromModel currentModel)
                |> Just
    in
    delta2builder >>> Maybe.map RouteUrl.Builder.toHashChange


getPathFromModel model =
    case getPage__ model of
        EntityListPage pageModel ->
            getPathFromEntityListPageModel pageModel

        CustomSyncSettingsPage ->
            [ "custom-sync" ]


hash2messages config location =
    let
        builder =
            RouteUrl.Builder.fromHash location.href
    in
    case RouteUrl.Builder.path builder of
        "custom-sync" :: [] ->
            [ config.navigateToPathMsg [ "custom-sync" ] ]

        _ ->
            routeUrlBuilderToMaybeEntityListPageModel builder
                ?|> (config.gotoEntityListPageMsg >> X.List.singleton)
                ?= [ config.gotoPageMsg initialPage ]
