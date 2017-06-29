module Entity.Main exposing (..)

import DomPorts
import Entity
import Model
import Return
import Toolkit.Helpers exposing (..)
import Toolkit.Operators exposing (..)
import X.Function exposing (..)
import X.Function.Infix exposing (..)
import List.Extra as List
import Maybe.Extra as Maybe
import Time


update :
    (Model.Msg -> Model.ReturnF)
    -> Entity.Entity
    -> Entity.Msg
    -> Model.ReturnF
update andThenUpdate entity msg =
    case msg of
        Entity.StartEditing ->
            Return.map (Model.startEditingEntity entity)
                >> DomPorts.autoFocusInputCmd

        Entity.NameChanged newName ->
            Return.map (Model.updateEditModeNameChanged newName entity)

        Entity.Save ->
            andThenUpdate Model.OnSaveCurrentForm

        Entity.ToggleDeleted ->
            Return.andThen (Model.toggleDeleteEntity entity)
                >> andThenUpdate Model.OnDeactivateEditingMode

        Entity.ToggleArchived ->
            Return.andThen (Model.toggleArchiveEntity entity)
                >> andThenUpdate Model.OnDeactivateEditingMode

        Entity.OnFocusIn ->
            Return.map (Model.setFocusInEntity entity)

        Entity.ToggleSelected ->
            Return.map (Model.toggleEntitySelection entity)

        Entity.Goto ->
            Return.map (Model.switchToEntityListViewFromEntity entity)
