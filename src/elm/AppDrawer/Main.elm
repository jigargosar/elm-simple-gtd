module AppDrawer.Main exposing (..)

import AppDrawer.Model exposing (..)
import Model
import Return
import X.Record


map =
    X.Record.over Model.appDrawerModel >> Return.map


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
            map toggleArchivedContexts

        OnToggleArchivedContexts ->
            map toggleArchivedContexts

        OnToggleArchivedProjects ->
            map toggleProjectShowArchived

        OnToggleOverlay ->
            map toggleOverlay
    )
        >> andThenUpdate Model.OnPersistLocalPref
