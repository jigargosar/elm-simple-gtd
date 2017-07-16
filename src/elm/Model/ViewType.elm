module Model.ViewType exposing (..)

import ViewType exposing (ViewType(EntityListView))


switchToView mainViewType model =
    { model | mainViewType = mainViewType }


maybeGetCurrentEntityListViewType model =
    case model.mainViewType of
        EntityListView viewType ->
            Just viewType

        _ ->
            Nothing



--getMainViewType : AppModel -> ViewType


getMainViewType =
    (.mainViewType)
