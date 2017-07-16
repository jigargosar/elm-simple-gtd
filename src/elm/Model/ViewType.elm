module Model.ViewType exposing (..)

import ViewType exposing (ViewType(EntityListView))


maybeGetEntityListViewType model =
    case model.mainViewType of
        EntityListView viewType ->
            Just viewType

        _ ->
            Nothing


getMainViewType =
    .mainViewType
