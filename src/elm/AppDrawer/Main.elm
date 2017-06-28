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
        OnToggleExpandContextList ->
            map toggleContextListExpanded

        OnToggleExpandProjectList ->
            map toggleProjectListExpanded

        OnToggleShowArchivedContexts ->
            map toggleContextShowArchived

        OnToggleShowArchivedProjects ->
            map toggleProjectShowArchived

        OnToggleOverlay ->
            map toggleOverlay
    )
        >> andThenUpdate Model.OnPersistLocalPref
