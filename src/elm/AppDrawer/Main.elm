module AppDrawer.Main exposing (..)

import AppDrawer.Model exposing (..)
import AppDrawer.Types exposing (Msg(..))
import Model
import Msg exposing (AppMsg)
import Return
import Types exposing (..)
import X.Record exposing (over, set)


type alias AppReturnF =
    Return.ReturnF AppMsg AppModel


mapOver =
    over Model.appDrawerModel >> Return.map


update :
    (Msg.AppMsg -> AppReturnF)
    -> AppDrawer.Types.Msg
    -> AppReturnF
update andThenUpdate msg =
    (case msg of
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
    )
        >> andThenUpdate Msg.OnPersistLocalPref
