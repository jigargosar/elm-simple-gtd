module Model.ViewType exposing (..)

import Document.Types exposing (getDocId)
import Entity.Types exposing (EntityListViewType(..))
import Model.Selection
import ViewType exposing (ViewType(EntityListView))


projectView =
    getDocId >> Entity.Types.ProjectView >> EntityListView


contextView =
    getDocId >> Entity.Types.ContextView >> EntityListView


switchToProjectView =
    projectView >> switchToView


switchToContextView =
    contextView >> switchToView



--switchToView : ViewType -> ModelF


switchToView mainViewType model =
    { model | mainViewType = mainViewType }
        |> Model.Selection.clearSelection


switchToContextsView =
    setEntityListViewType ContextsView


switchToProjectsView =
    setEntityListViewType ProjectsView


setEntityListViewType =
    EntityListView >> switchToView


maybeGetCurrentEntityListViewType model =
    case model.mainViewType of
        EntityListView viewType ->
            Just viewType

        _ ->
            Nothing



--getMainViewType : AppModel -> ViewType


getMainViewType =
    (.mainViewType)
