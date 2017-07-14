module Entity.Main exposing (..)

import Context
import Document
import Document.Types exposing (getDocId)
import DomPorts
import Entity
import Entity.Types exposing (Entity(GroupEntity, TodoEntity), EntityId(..), EntityListViewType(BinView, ContextView, ContextsView, DoneView, ProjectView, ProjectsView, RecentView), GroupEntityType(ContextEntity, ProjectEntity), createContextEntity, createProjectEntity, getDocIdFromEntityId)
import ExclusiveMode.Types exposing (..)
import GroupDoc
import GroupDoc.EditForm exposing (createEditContextForm, createEditProjectForm)
import Maybe.Extra
import Model.Internal exposing (setExclusiveMode)
import Model.Selection
import Model.ViewType
import Msg exposing (AppMsg)
import Project
import Return exposing (andThen)
import Set
import Store
import Stores
import Todo
import Todo.Msg
import Todo.Types exposing (TodoAction(..))
import TodoMsg
import Types exposing (AppModel, ModelF, ModelReturnF, ReturnF)
import Toolkit.Operators exposing (..)
import Tuple2
import X.Function.Infix exposing (..)
import X.Return


map =
    Return.map


update :
    (AppMsg -> ReturnF)
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

        Entity.Types.OnEntityUpdate entityId entityUpdateMsg ->
            onUpdate andThenUpdate entityId entityUpdateMsg


onUpdate :
    (AppMsg -> ReturnF)
    -> EntityId
    -> Entity.Types.EntityUpdateMsg
    -> ReturnF
onUpdate andThenUpdate entityId msg =
    case msg of
        Entity.Types.OnStartEditingEntity ->
            startEditingEntity andThenUpdate entityId
                >> DomPorts.autoFocusInputRCmd

        Entity.Types.OnEntityTextChanged newName ->
            Return.map (updateEditModeTextChanged newName)

        Entity.Types.OnEntityToggleDeleted ->
            Return.andThen (toggleDeleteEntity entityId)
                >> andThenUpdate Msg.OnDeactivateEditingMode

        Entity.Types.OnEntityToggleArchived ->
            let
                toggleArchivedEntity =
                    case entityId of
                        ContextId id ->
                            Stores.updateContext id GroupDoc.toggleArchived
                                |> Return.andThen

                        ProjectId id ->
                            Stores.updateProject id GroupDoc.toggleArchived
                                |> Return.andThen

                        TodoId id ->
                            Todo.Msg.OnUpdateTodoAndMaybeSelectedAndDeactivateEditingMode id TA_ToggleDone
                                |> Msg.OnTodoMsg
                                |> andThenUpdate
            in
                toggleArchivedEntity
                    >> andThenUpdate Msg.OnDeactivateEditingMode

        Entity.Types.OnFocusInEntity ->
            Return.map (Stores.setFocusInEntityWithEntityId entityId)

        Entity.Types.OnToggleSelectedEntity ->
            Return.map (toggleEntitySelection entityId)

        Entity.Types.OnGotoEntity ->
            Return.map (switchToEntityListViewFromEntity entityId)


toggleEntitySelection entityId =
    Model.Selection.updateSelectedEntityIdSet (toggleSetMember (getDocIdFromEntityId entityId))


toggleSetMember item set =
    if Set.member item set then
        Set.remove item set
    else
        Set.insert item set


switchToEntityListViewFromEntity entityId model =
    let
        maybeEntityListViewType =
            Model.ViewType.maybeGetCurrentEntityListViewType model
    in
        entityId
            |> toViewType model maybeEntityListViewType
            |> (Model.ViewType.setEntityListViewType # model)


toggleDeleteEntity : EntityId -> ModelReturnF
toggleDeleteEntity entityId =
    case entityId of
        ContextId id ->
            Stores.updateContext id Document.toggleDeleted

        ProjectId id ->
            Stores.updateProject id Document.toggleDeleted

        TodoId id ->
            Stores.updateTodo (TA_ToggleDeleted) id


createAndEditNewProject andThenUpdate model =
    Store.insert (Project.init "<New Project>" model.now) model.projectStore
        |> Tuple2.mapSecond (Stores.setProjectStore # model)
        |> (\( project, model ) ->
                let
                    entity =
                        (createProjectEntity project)
                in
                    Return.singleton model
                        |> startEditingEntity andThenUpdate (Entity.toEntityId entity)
           )


createAndEditNewContext andThenUpdate model =
    Store.insert (Context.init "<New Context>" model.now) model.contextStore
        |> Tuple2.mapSecond (Stores.setContextStore # model)
        |> (\( context, model ) ->
                let
                    entity =
                        (createContextEntity context)
                in
                    Return.singleton model
                        |> startEditingEntity andThenUpdate (Entity.toEntityId entity)
           )


editProjectSetName =
    GroupDoc.EditForm.setName >>> XMEditProject


editContextSetName =
    GroupDoc.EditForm.setName >>> XMEditContext


startEditingEntity : (AppMsg -> ReturnF) -> EntityId -> ReturnF
startEditingEntity andThenUpdate entityId =
    case entityId of
        ContextId id ->
            X.Return.mapModelWithMaybeF
                (Stores.findContextById id)
                (createEditContextForm >> XMEditContext >> setExclusiveMode)

        ProjectId id ->
            X.Return.mapModelWithMaybeF
                (Stores.findProjectById id)
                (createEditProjectForm >> XMEditContext >> setExclusiveMode)

        TodoId id ->
            X.Return.withMaybe (Stores.findTodoById id)
                (TodoMsg.onStartEditingTodo >> andThenUpdate)


updateEditModeTextChanged newName model =
    model
        |> case model.editMode of
            XMEditContext ecm ->
                setExclusiveMode (editContextSetName newName ecm)

            XMEditProject epm ->
                setExclusiveMode (editProjectSetName newName epm)

            _ ->
                identity


toViewType : AppModel -> Maybe EntityListViewType -> EntityId -> EntityListViewType
toViewType appModel maybeCurrentEntityListViewType entityId =
    case entityId of
        ContextId id ->
            ContextView id

        ProjectId id ->
            ProjectView id

        TodoId id ->
            let
                getViewTypeForTodo todo =
                    maybeCurrentEntityListViewType
                        ?|> getTodoGotoGroupView todo
                        ?= (Todo.getContextId todo |> ContextView)
            in
                Stores.findTodoById id appModel
                    ?|> getViewTypeForTodo
                    |> Maybe.Extra.orElse maybeCurrentEntityListViewType
                    ?= ContextsView


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
