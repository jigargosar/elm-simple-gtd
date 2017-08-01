module Page exposing (..)

import Pages.EntityList
import Pages.EntityListOld exposing (..)
import RouteUrl.Builder
import X.Function.Infix exposing (..)


type Page
    = CustomSyncSettingsPage String
    | EntityListPage Pages.EntityList.Model


type PageMsg
    = PageMsg_SetPage Page
    | PageMsg_NavigateToPath (List String)


initialModel =
    EntityListPage Pages.EntityList.defaultModel


getPage__ =
    .page


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
    [ config.navigateToPathMsg path ]
