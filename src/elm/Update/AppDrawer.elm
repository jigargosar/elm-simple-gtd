module Update.AppDrawer exposing (update)

import AppDrawer.Model exposing (..)
import AppDrawer.Types exposing (Msg(..))
import Return
import X.Record exposing (..)


type alias SubModel model =
    { model
        | appDrawerModel : AppDrawer.Model.Model
    }


type alias SubReturnF msg model =
    Return.ReturnF msg (SubModel model)


appDrawerModel =
    fieldLens .appDrawerModel (\s b -> { b | appDrawerModel = s })


mapOver =
    over appDrawerModel >> Return.map


update :
    AppDrawer.Types.Msg
    -> SubReturnF msg model
update msg =
    case msg of
        OnToggleContextsExpanded ->
            mapOver (toggleGroupListExpanded contexts)

        OnToggleProjectsExpanded ->
            mapOver (toggleGroupListExpanded projects)

        OnToggleArchivedContexts ->
            mapOver (toggleGroupArchivedListExpanded contexts)

        OnToggleArchivedProjects ->
            mapOver (toggleGroupArchivedListExpanded projects)

        OnToggleOverlay ->
            mapOver toggleOverlay

        OnWindowResizeTurnOverlayOff ->
            mapOver (set isOverlayOpen False)
