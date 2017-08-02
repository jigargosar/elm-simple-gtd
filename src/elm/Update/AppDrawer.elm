module Update.AppDrawer exposing (update)

import AppDrawer.Model exposing (..)
import AppDrawer.Types exposing (AppDrawerMsg(..))
import Ports
import X.Record exposing (..)
import X.Return exposing (..)


type alias SubModel model =
    { model
        | appDrawerModel : AppDrawer.Model.AppDrawerModel
    }


type alias SubReturnF msg model =
    ReturnF msg (SubModel model)


appDrawerModel =
    fieldLens .appDrawerModel (\s b -> { b | appDrawerModel = s })


mapOver =
    over appDrawerModel >> map


mapOverAndPersist fn =
    map (over appDrawerModel fn)
        >> effect (get appDrawerModel >> AppDrawer.Model.getOfflineStoreKeyValue >> Ports.persistToOfflineStore)


update :
    AppDrawer.Types.AppDrawerMsg
    -> SubReturnF msg model
update msg =
    case msg of
        OnToggleContextsExpanded ->
            mapOverAndPersist (toggleGroupListExpanded contexts)

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
