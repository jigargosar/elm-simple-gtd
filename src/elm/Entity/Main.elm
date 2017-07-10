module Entity.Main exposing (..)

import Context
import Document
import DomPorts
import Entity
import Entity.Types exposing (Entity, createContextEntity, createProjectEntity)
import ExclusiveMode
import ExclusiveMode.Types exposing (ExclusiveMode(XMEditContext, XMEditProject))
import GroupDoc
import Model
import Model.ExMode
import Model.Selection
import Model.ViewType
import Msg exposing (Msg)
import Project
import Return
import Set
import Store
import Stores
import Todo.Msg
import Todo.Types exposing (TodoAction(..))
import Types exposing (ModelF, ModelReturnF, ReturnF)
import Toolkit.Operators exposing (..)
import Tuple2


map =
    Return.map


update :
    (Msg -> ReturnF)
    -> Entity.Types.EntityMsg
    -> ReturnF
update andThenUpdate msg =
    case msg of
        Entity.Types.OnNewProject ->
            map createAndEditNewProject
                >> DomPorts.autoFocusInputCmd

        Entity.Types.OnNewContext ->
            map createAndEditNewContext
                >> DomPorts.autoFocusInputCmd

        Entity.Types.OnUpdate entity entityUpdateMsg ->
            onUpdate andThenUpdate entity entityUpdateMsg


onUpdate :
    (Msg -> ReturnF)
    -> Entity
    -> Entity.Types.EntityUpdateMsg
    -> ReturnF
onUpdate andThenUpdate entity msg =
    case msg of
        Entity.Types.OnStartEditing ->
            Return.map (startEditingEntity entity)
                >> DomPorts.autoFocusInputCmd

        Entity.Types.OnNameChanged newName ->
            Return.map (updateEditModeNameChanged newName entity)

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


toggleDeleteEntity : Entity -> ModelReturnF
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


createAndEditNewProject model =
    Store.insert (Project.init "<New Project>" model.now) model.projectStore
        |> Tuple2.mapSecond (Stores.setProjectStore # model)
        |> (\( project, model ) ->
                model
                    |> startEditingEntity (createProjectEntity project)
           )


createAndEditNewContext model =
    Store.insert (Context.init "<New Context>" model.now) model.contextStore
        |> Tuple2.mapSecond (Stores.setContextStore # model)
        |> (\( context, model ) ->
                model
                    |> startEditingEntity (createContextEntity context)
           )


setEditMode =
    Model.ExMode.setEditMode


startEditingEntity : Entity -> ModelF
startEditingEntity entity model =
    Model.ExMode.setEditMode (ExclusiveMode.createEntityEditForm entity) model


updateEditModeNameChanged newName entity model =
    model
        |> case model.editMode of
            XMEditContext ecm ->
                setEditMode (ExclusiveMode.editContextSetName newName ecm)

            XMEditProject epm ->
                setEditMode (ExclusiveMode.editProjectSetName newName epm)

            _ ->
                identity
