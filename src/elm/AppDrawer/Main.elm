module AppDrawer.Main exposing (..)

import AppDrawer.Model
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
    -> Time.Time
    -> AppDrawer.Model.Msg
    -> Model.ReturnF
update andThenUpdate now msg =
    case msg of
        AppDrawer.Model.OnToggleExpandContextList ->
            identity

        AppDrawer.Model.OnToggleExpandProjectList ->
            identity
