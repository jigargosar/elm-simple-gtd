module AppDrawer.Main exposing (..)

import AppDrawer.Model exposing (..)
import Model
import Return
import X.Record exposing (over, toggle)


map =
    over Model.appDrawerModel >> Return.map


mapToggle =
    toggle >> map


update :
    (Model.Msg -> Model.ReturnF)
    -> Msg
    -> Model.ReturnF
update andThenUpdate msg =
    (case msg of
        OnToggleContexts ->
            map toggleContexts

        OnToggleProjects ->
            map toggleProjects

        OnToggleArchivedContexts ->
            map (toggleGroupArchivedListExpanded contexts)

        OnToggleArchivedProjects ->
            map (toggleGroupArchivedListExpanded projects)

        OnToggleOverlay ->
            mapToggle isOverlayOpen
    )
        >> andThenUpdate Model.OnPersistLocalPref
