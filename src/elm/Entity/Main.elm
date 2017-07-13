module Entity.Main exposing (..)

import Context
import Document
import Document.Types exposing (getDocId)
import DomPorts
import Entity
import Entity.Types exposing (Entity(GroupEntity, TodoEntity), EntityListViewType(BinView, ContextView, ContextsView, DoneView, ProjectView, ProjectsView, RecentView), GroupEntityType(ContextEntity, ProjectEntity), createContextEntity, createProjectEntity)
import ExclusiveMode.Types exposing (..)
import GroupDoc
import GroupDoc.EditForm
import Model.Internal exposing (setExclusiveMode)
import Model.Selection
import Model.ViewType
import Msg exposing (Msg)
import Project
import Return exposing (andThen)
import Set
import Store
import Stores
import Todo
import Todo.Msg
import Todo.Types exposing (TodoAction(..))
import Types exposing (ModelF, ModelReturnF, ReturnF)
import Toolkit.Operators exposing (..)
import Tuple2
import X.Function.Infix exposing (..)


map =
    Return.map


update :
    (Msg -> ReturnF)
    -> Entity.Types.EntityMsg
    -> ReturnF
update andThenUpdate msg =
    case msg of
        Entity.Types.OnNewProject ->
            andThen (createAndEditNewProject andThenUpdate)
                >> DomPorts.autoFocusInputRCmd

        Entity.Types.OnNewContext ->
            andThen (createAndEditNewContext andThenUpdate)
                >> DomPorts.autoFocusInputRCmd

        Entity.Types.OnUpdate entity entityUpdateMsg ->
            onUpdate andThenUpdate entity entityUpdateMsg


onUpdate :
    (Msg -> ReturnF)
    -> Entity
    -> Entity.Types.EntityUpdateMsg
    -> ReturnF
onUpdate andThenUpdate entity msg =
    case msg of
        Entity.Types.OnStartEditingEntity ->
            andThen (\model -> startEditingEntity andThenUpdate model.now entity model)
                >> DomPorts.autoFocusInputRCmd

        Entity.Types.OnEntityTextChanged newName ->
            Return.map (updateEditModeNameChanged newName entity)

        Entity.Types.OnSaveEntityForm ->
            andThenUpdate Msg.OnSaveCurrentForm

        Entity.Types.OnEntityToggleDeleted ->
            Return.andThen (toggleDeleteEntity entity)
                >> andThenUpdate Msg.OnDeactivateEditingMode

        Entity.Types.OnEntityToggleArchived ->
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

        Entity.Types.OnFocusInEntity ->
            Return.map (Stores.setFocusInEntity entity)

        Entity.Types.OnToggleSelectedEntity ->
            Return.map (toggleEntitySelection entity)

        Entity.Types.OnGotoEntity ->
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
            |> toViewType maybeEntityListViewType
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


createAndEditNewProject andThenUpdate model =
    Store.insert (Project.init "<New Project>" model.now) model.projectStore
        |> Tuple2.mapSecond (Stores.setProjectStore # model)
        |> (\( project, model ) ->
                model
                    |> startEditingEntity andThenUpdate model.now (createProjectEntity project)
           )


createAndEditNewContext andThenUpdate model =
    Store.insert (Context.init "<New Context>" model.now) model.contextStore
        |> Tuple2.mapSecond (Stores.setContextStore # model)
        |> (\( context, model ) ->
                model
                    |> startEditingEntity andThenUpdate model.now (createContextEntity context)
           )


editProjectSetName =
    GroupDoc.EditForm.setName >>> XMEditProject


editContextSetName =
    GroupDoc.EditForm.setName >>> XMEditContext


startEditingEntity andThenUpdate now entity model =
    Return.singleton model
        |> case entity of
            GroupEntity g ->
                case g of
                    ContextEntity context ->
                        map (setExclusiveMode (context |> GroupDoc.EditForm.forContext >> XMEditContext))

                    ProjectEntity p ->
                        map (setExclusiveMode (p |> GroupDoc.EditForm.forProject >> XMEditProject))

            TodoEntity todo ->
                Debug.log "startEditingEntity : This method should not be called for todo. We should probably get rid of entity Main stuff, or bring all types of edits here. which doesn't seem fesable, since there are different types of edit modes for todo."


updateEditModeNameChanged newName entity model =
    model
        |> case model.editMode of
            XMEditContext ecm ->
                setExclusiveMode (editContextSetName newName ecm)

            XMEditProject epm ->
                setExclusiveMode (editProjectSetName newName epm)

            _ ->
                identity


toViewType : Maybe EntityListViewType -> Entity -> EntityListViewType
toViewType maybePrevView entity =
    case entity of
        GroupEntity group ->
            case group of
                ContextEntity model ->
                    getDocId model |> ContextView

                ProjectEntity model ->
                    getDocId model |> ProjectView

        TodoEntity model ->
            maybePrevView
                ?|> getTodoGotoGroupView model
                ?= (Todo.getContextId model |> ContextView)


getTodoGotoGroupView todo prevView =
    let
        contextView =
            Todo.getContextId todo |> ContextView

        projectView =
            Todo.getProjectId todo |> ProjectView
    in
        case prevView of
            ProjectsView ->
                contextView

            ProjectView _ ->
                contextView

            ContextsView ->
                projectView

            ContextView _ ->
                projectView

            BinView ->
                ContextsView

            DoneView ->
                ContextsView

            RecentView ->
                ContextsView
