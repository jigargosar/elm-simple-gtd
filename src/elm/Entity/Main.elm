module Entity.Main exposing (..)

import DomPorts
import Entity
import Entity.Types exposing (EntityType)
import GroupDoc
import Model
import Model.ExMode
import Msg
import Return
import Stores
import Todo.Msg
import Todo.Types exposing (TodoAction(..))
import Types exposing (ReturnF)


update :
    (Msg.Msg -> ReturnF)
    -> EntityType
    -> Entity.Types.EntityMsg
    -> ReturnF
update andThenUpdate entity msg =
    case msg of
        Entity.Types.OnStartEditing ->
            Return.map (Model.ExMode.startEditingEntity entity)
                >> DomPorts.autoFocusInputCmd

        Entity.Types.OnNameChanged newName ->
            Return.map (Model.ExMode.updateEditModeNameChanged newName entity)

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
                                        Stores.updateContext entityId GroupDoc.toggleArchived

                                    Entity.Types.ProjectEntity project ->
                                        Stores.updateProject entityId GroupDoc.toggleArchived
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
            Return.map (Stores.setFocusInEntity entity)

        Entity.Types.OnToggleSelected ->
            Return.map (Model.toggleEntitySelection entity)

        Entity.Types.OnGoto ->
            Return.map (Model.switchToEntityListViewFromEntity entity)
