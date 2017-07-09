module Entity.Main exposing (..)

import Document
import DomPorts
import Entity
import Entity.Types exposing (EntityType)
import GroupDoc
import Model
import Model.ExMode
import Model.Selection
import Model.ViewType
import Msg
import Return
import Set
import Stores
import Todo.Msg
import Todo.Types exposing (TodoAction(..))
import Types exposing (ModelReturnF, ReturnF)
import Toolkit.Operators exposing (..)


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
            Return.andThen (toggleDeleteEntity entity)
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
            Return.map (toggleEntitySelection entity)

        Entity.Types.OnGoto ->
            Return.map (switchToEntityListViewFromEntity entity)


toggleEntitySelection entity =
    Model.Selection.updateSelectedEntityIdSet (toggleSetMember (Entity.getId entity))


toggleSetMember item set =
    if Set.member item set then
        Set.remove item set
    else
        Set.insert item set


switchToEntityListViewFromEntity entity model =
    let
        maybeEntityListViewType =
            Model.ViewType.maybeGetCurrentEntityListViewType model
    in
        entity
            |> Entity.toViewType maybeEntityListViewType
            |> (Model.ViewType.setEntityListViewType # model)


toggleDeleteEntity : EntityType -> ModelReturnF
toggleDeleteEntity entity model =
    let
        entityId =
            Entity.getId entity
    in
        model
            |> case entity of
                Entity.Types.GroupEntity g ->
                    case g of
                        Entity.Types.ContextEntity context ->
                            Stores.updateContext entityId Document.toggleDeleted

                        Entity.Types.ProjectEntity project ->
                            Stores.updateProject entityId Document.toggleDeleted

                Entity.Types.TodoEntity todo ->
                    Stores.updateTodo (TA_ToggleDeleted) entityId
