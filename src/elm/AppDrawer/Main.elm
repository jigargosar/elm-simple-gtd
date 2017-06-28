module AppDrawer.Main exposing (..)

import AppDrawer.Model
import Model


update :
    (Model.Msg -> Model.ReturnF)
    -> AppDrawer.Model.Msg
    -> Model.ReturnF
update andThenUpdate msg =
    (case msg of
        AppDrawer.Model.OnToggleExpandContextList ->
            Model.mapOverAppDrawerModel AppDrawer.Model.toggleContextListExpanded

        AppDrawer.Model.OnToggleExpandProjectList ->
            Model.mapOverAppDrawerModel AppDrawer.Model.toggleProjectListExpanded

        AppDrawer.Model.OnToggleShowArchivedContexts ->
            Model.mapOverAppDrawerModel AppDrawer.Model.toggleContextShowArchived

        AppDrawer.Model.OnToggleShowArchivedProjects ->
            Model.mapOverAppDrawerModel AppDrawer.Model.toggleProjectShowArchived

        AppDrawer.Model.OnToggleOverlay ->
            Model.mapOverAppDrawerModel AppDrawer.Model.toggleOverlay
    )
        >> andThenUpdate Model.OnPersistLocalPref
