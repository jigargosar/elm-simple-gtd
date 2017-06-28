module AppDrawer.Main exposing (..)

import AppDrawer.Model exposing (..)
import Model
import Return
import X.Record exposing (over, toggle)


map =
    over Model.appDrawerModel >> Return.map


update :
    (Model.Msg -> Model.ReturnF)
    -> Msg
    -> Model.ReturnF
update andThenUpdate msg =
    (case msg of
        OnToggleContextsExpanded ->
            map (toggleGroupListExpanded contexts)

        OnToggleProjectsExpanded ->
            map (toggleGroupListExpanded projects)

        OnToggleArchivedContexts ->
            map (toggleGroupArchivedListExpanded contexts)

        OnToggleArchivedProjects ->
            map (toggleGroupArchivedListExpanded projects)

        OnToggleOverlay ->
            map toggleOverlay
    )
        >> andThenUpdate Model.OnPersistLocalPref
