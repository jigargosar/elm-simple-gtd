module Page exposing (..)

import Pages.EntityList
import Pages.EntityListOld exposing (..)
import RouteUrl.Builder
import Toolkit.Helpers exposing (..)
import Toolkit.Operators exposing (..)
import X.Function.Infix exposing (..)
import X.List


type Page
    = Old_EntityListPage Old_EntityListPageModel
    | CustomSyncSettingsPage String
    | EntityListPage Pages.EntityList.Model


type PageMsg
    = PageMsg_SetPage Page
    | PageMsg_SetEntityListPage Old_EntityListPageModel
    | PageMsg_NavigateToPath (List String)


maybeGetEntityListPage model =
    case getPage__ model of
        Old_EntityListPage pageModel ->
            Just pageModel

        _ ->
            Nothing


getPage__ =
    .page


initialPage =
    Old_EntityListPage Pages.EntityListOld.initialEntityListPageModel


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
        Old_EntityListPage pageModel ->
            getPathFromEntityListPageModel pageModel

        CustomSyncSettingsPage _ ->
            [ "custom-sync" ]

        EntityListPage model ->
            model.path


routeUrlBuilderToMaybeEntityListPageModel builder =
    case RouteUrl.Builder.path builder of
        "done" :: [] ->
            DoneView |> Just

        _ ->
            Nothing


hash2messages config location =
    let
        builder =
            RouteUrl.Builder.fromHash location.href

        path =
            RouteUrl.Builder.path builder
    in
    routeUrlBuilderToMaybeEntityListPageModelOld builder
        ?|> (config.gotoEntityListPageMsg >> X.List.singleton)
        ?= [ config.navigateToPathMsg path ]
