module Entity.Main exposing (..)

import DomPorts
import Entity
import Entity.Types exposing (EntityType)
import GroupDoc
import Model
import Msg
import Return
import Todo.Msg
import Todo.Types exposing (TodoAction(..))


update :
    (Msg.Msg -> Model.ReturnF)
    -> EntityType
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
                            Entity.Types.GroupEntity g ->
                                (case g of
                                    Entity.Types.ContextEntity context ->
                                        Model.updateContext entityId GroupDoc.toggleArchived

                                    Entity.Types.ProjectEntity project ->
                                        Model.updateProject entityId GroupDoc.toggleArchived
                                )
                                    |> Return.andThen

                            Entity.Types.TodoEntity todo ->
                                Todo.Msg.OnUpdateTodoAndMaybeSelectedAndDeactivateEditingMode entityId TA_ToggleDone
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
