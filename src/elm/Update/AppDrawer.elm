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


type alias ReturnF =
    X.Return.ReturnF AppDrawerMsg AppDrawerModel


mapOverAndPersist fn =
    map fn
        >> effect
            (AppDrawer.Model.getOfflineStoreKeyValue
                >> Ports.persistToOfflineStore
            )


update : AppDrawerMsg -> ReturnF
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
            mapOverAndPersist (set isOverlayOpen False)
