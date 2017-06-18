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
            Return.map (Model.overAppDrawerModel (AppDrawer.Model.toggleContextListExpanded))

        AppDrawer.Model.OnToggleExpandProjectList ->
            Return.map (Model.overAppDrawerModel (AppDrawer.Model.toggleProjectListExpanded))
