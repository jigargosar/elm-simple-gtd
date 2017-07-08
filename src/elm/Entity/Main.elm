module Entity.Main exposing (..)

import DomPorts
import Entity
import Entity.Types
import GroupDoc
import Model
import Msg
import Return
import Todo
import Toolkit.Helpers exposing (..)
import Toolkit.Operators exposing (..)
import X.Function exposing (..)
import X.Function.Infix exposing (..)
import List.Extra as List
import Maybe.Extra as Maybe
import Time
import Todo.Msg


update :
    (Msg.Msg -> Model.ReturnF)
    -> Entity.Entity
    -> Entity.Types.Msg
    -> Model.ReturnF
update andThenUpdate entity msg =
    case msg of
        Entity.Types.OnStartEditing ->
            Return.map (Model.startEditingEntity entity)
                >> DomPorts.autoFocusInputCmd

        Entity.Types.OnNameChanged newName ->
            Return.map (Model.updateEditModeNameChanged newName entity)

        Entity.Types.OnSave ->
            andThenUpdate Msg.OnSaveCurrentForm

        Entity.Types.OnToggleDeleted ->
            Return.andThen (Model.toggleDeleteEntity entity)
                >> andThenUpdate Msg.OnDeactivateEditingMode

        Entity.Types.OnToggleArchived ->
            let
                toggleArchivedEntity entity =
                    let
                        entityId =
                            Entity.getId entity
                    in
                        case entity of
                            Entity.Types.Group g ->
                                (case g of
                                    Entity.Types.Context context ->
                                        Model.updateContext entityId GroupDoc.toggleArchived

                                    Entity.Types.Project project ->
                                        Model.updateProject entityId GroupDoc.toggleArchived
                                )
                                    |> Return.andThen

                            Entity.Types.Todo todo ->
                                Todo.Msg.OnUpdateTodoAndMaybeSelectedAndDeactivateEditingMode entityId Todo.ToggleDone
                                    |> Msg.OnTodoMsg
                                    |> andThenUpdate
            in
                toggleArchivedEntity entity
                    >> andThenUpdate Msg.OnDeactivateEditingMode

        Entity.Types.OnOnFocusIn ->
            Return.map (Model.setFocusInEntity entity)

        Entity.Types.OnToggleSelected ->
            Return.map (Model.toggleEntitySelection entity)

        Entity.Types.OnGoto ->
            Return.map (Model.switchToEntityListViewFromEntity entity)
