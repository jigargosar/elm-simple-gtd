module AppDrawer.Main exposing (..)

import AppDrawer.Model exposing (..)
import AppDrawer.Types exposing (Msg(..))
import Model
import Msg
import Return
import ReturnTypes exposing (..)
import Window
import X.Record exposing (over, set)


mapOver =
    over Model.appDrawerModel >> Return.map


subscriptions model =
    Sub.batch
        [ Window.resizes (\_ -> OnWindowResizeTurnOverlayOff) ]
        |> Sub.map Msg.OnAppDrawerMsg


update :
    (Msg.AppMsg -> ReturnF)
    -> AppDrawer.Types.Msg
    -> ReturnF
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
