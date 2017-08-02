module Page exposing (..)

import Pages.EntityList
import RouteUrl.Builder
import X.Function.Infix exposing (..)


type Page
    = EntityListPage Pages.EntityList.Model


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
        EntityListPage model ->
            model.path


hash2messages config location =
    let
        builder =
            RouteUrl.Builder.fromHash location.href

        path =
            RouteUrl.Builder.path builder
    in
    [ config.navigateToPathMsg path ]
