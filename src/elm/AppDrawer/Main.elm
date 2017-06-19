module AppDrawer.Main exposing (..)

import AppDrawer.Model
import Return
import Toolkit.Helpers exposing (..)
import Toolkit.Operators exposing (..)
import Ext.Function exposing (..)
import Ext.Function.Infix exposing (..)
import List.Extra as List
import Maybe.Extra as Maybe
import Model
import Time


update :
    (Model.Msg -> Model.ReturnF)
    -> AppDrawer.Model.Msg
    -> Model.ReturnF
update andThenUpdate msg =
    case msg of
        AppDrawer.Model.OnToggleExpandContextList ->
            Model.mapOverAppDrawerModel AppDrawer.Model.toggleContextListExpanded
                >> andThenUpdate Model.OnPersistLocalPref

        AppDrawer.Model.OnToggleExpandProjectList ->
            Model.mapOverAppDrawerModel AppDrawer.Model.toggleProjectListExpanded
                >> andThenUpdate Model.OnPersistLocalPref

        AppDrawer.Model.OnToggleShowArchivedContexts ->
            Model.mapOverAppDrawerModel AppDrawer.Model.toggleContextShowArchived
                >> andThenUpdate Model.OnPersistLocalPref

        AppDrawer.Model.OnToggleShowArchivedProjects ->
            Model.mapOverAppDrawerModel AppDrawer.Model.toggleProjectShowArchived
                >> andThenUpdate Model.OnPersistLocalPref
