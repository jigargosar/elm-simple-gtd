module Update.AppDrawer exposing (..)

import AppDrawer.Model exposing (..)
import AppDrawer.Types exposing (AppDrawerMsg(..))
import Ports
import Window
import X.Record exposing (..)
import X.Return exposing (..)


subscriptions =
    Sub.batch
        [ Window.resizes (\_ -> OnWindowResizeTurnOverlayOff) ]


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
    mapOver fn
        >> effect
            (get appDrawerModel
                >> AppDrawer.Model.getOfflineStoreKeyValue
                >> Ports.persistToOfflineStore
            )


update :
    AppDrawer.Types.AppDrawerMsg
    -> SubReturnF msg model
update msg =
    case msg of
        OnToggleContextsExpanded ->
            mapOverAndPersist (toggleGroupListExpanded contexts)

        OnToggleProjectsExpanded ->
            mapOverAndPersist (toggleGroupListExpanded projects)

        OnToggleArchivedContexts ->
            mapOverAndPersist (toggleGroupArchivedListExpanded contexts)

        OnToggleArchivedProjects ->
            mapOverAndPersist (toggleGroupArchivedListExpanded projects)

        OnToggleOverlay ->
            mapOverAndPersist toggleOverlay

        OnWindowResizeTurnOverlayOff ->
            mapOver (set isOverlayOpen False)
