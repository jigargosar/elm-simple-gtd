module Routes exposing (..)

import Entity
import Maybe.Extra
import Model as Model
import Model exposing (Msg)
import Navigation exposing (Location)
import RouteUrl.Builder as Builder exposing (..)
import RouteUrl exposing (UrlChange)
import X.Function.Infix exposing (..)
import Model exposing (..)
import X.List


delta2builder : Model -> Model -> Maybe Builder
delta2builder previous current =
    builder
        |> replacePath (getPathFromModel current)
        |> Just


getPathFromModel model =
    case Model.getMainViewType model of
        EntityListView viewType ->
            Entity.getPathFromViewType viewType

        SyncView ->
            [ "custom-sync" ]


delta2hash : Model -> Model -> Maybe UrlChange
delta2hash =
    delta2builder >>> Maybe.map toHashChange


builder2messages : Builder -> List Msg
builder2messages builder =
    Entity.routeUrlBuilderToMaybeListViewType builder
        |> Maybe.Extra.unpack
            (\_ ->
                case path builder of
                    "custom-sync" :: [] ->
                        [ Model.OnSetViewType SyncView ]

                    _ ->
                        -- If nothing provided for this part of the URL, return empty list
                        [ Model.OnSetViewType Model.defaultView ]
            )
            (Model.onSetEntityListView >> X.List.singleton)


hash2messages : Location -> List Msg
hash2messages location =
    builder2messages (fromHash location.href)
