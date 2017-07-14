module Entity.Main exposing (..)

import Context
import Document
import Document.Types exposing (getDocId)
import DomPorts
import Entity
import Entity.Types exposing (..)
import ExclusiveMode.Types exposing (..)
import GroupDoc
import GroupDoc.Form exposing (createAddGroupDocForm, createEditContextForm, createEditProjectForm)
import GroupDoc.Types exposing (GroupDocType(..))
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
        EM_StartAddingContext ->
            --            let
            --                createAndEditNewContext andThenUpdate model =
            --                    Store.insert (Context.init "<New Context>" model.now) model.contextStore
            --                        |> Tuple2.mapSecond (Stores.setContextStore # model)
            --                        |> (\( context, model ) ->
            --                                let
            --                                    entity =
            --                                        (createContextEntity context)
            --                                in
            --                                    Return.singleton model
            --                                        |> startEditingEntity andThenUpdate (Entity.toEntityId entity)
            --                           )
            --            in
            map (createAddGroupDocForm ContextGroupDoc |> XMGroupDocForm >> setExclusiveMode)
                >> DomPorts.autoFocusInputRCmd

        EM_StartAddingProject ->
            --            let
            --                createAndEditNewProject andThenUpdate model =
            --                    Store.insert (Project.init "<New Project>" model.now) model.projectStore
            --                        |> Tuple2.mapSecond (Stores.setProjectStore # model)
            --                        |> (\( project, model ) ->
            --                                let
            --                                    entity =
            --                                        (createProjectEntity project)
            --                                in
            --                                    Return.singleton model
            --                                        |> startEditingEntity andThenUpdate (Entity.toEntityId entity)
            --                           )
            --            in
            map (createAddGroupDocForm ProjectGroupDoc |> XMGroupDocForm >> setExclusiveMode)
                >> DomPorts.autoFocusInputRCmd

        EM_Update entityId action ->
            onUpdate andThenUpdate entityId action


onUpdate :
    (AppMsg -> ReturnF)
    -> EntityId
    -> Entity.Types.EntityUpdateAction
    -> ReturnF
onUpdate andThenUpdate entityId action =
    case action of
        EUA_StartEditing ->
            startEditingEntity andThenUpdate entityId
                >> DomPorts.autoFocusInputRCmd

        EUA_SetFormText newName ->
            Return.map (updateEditModeTextChanged newName)

        EUA_ToggleDeleted ->
            Return.andThen (toggleDeleteEntity entityId)
                >> andThenUpdate Msg.OnDeactivateEditingMode

        EUA_ToggleArchived ->
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

        EUA_OnFocusIn ->
            Return.map (Stores.setFocusInEntityWithEntityId entityId)

        EUA_ToggleSelection ->
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


startEditingEntity : (AppMsg -> ReturnF) -> EntityId -> ReturnF
startEditingEntity andThenUpdate entityId =
    case entityId of
        ContextId id ->
            X.Return.mapModelWithMaybeF
                (Stores.findContextById id)
                (createEditContextForm >> XMGroupDocForm >> setExclusiveMode)

        ProjectId id ->
            X.Return.mapModelWithMaybeF
                (Stores.findProjectById id)
                (createEditProjectForm >> XMGroupDocForm >> setExclusiveMode)

        TodoId id ->
            X.Return.withMaybe (Stores.findTodoById id)
                (TodoMsg.onStartEditingTodo >> andThenUpdate)


updateEditModeTextChanged newName model =
    model
        |> case model.editMode of
            XMGroupDocForm form ->
                setExclusiveMode (GroupDoc.Form.setName newName form |> XMGroupDocForm)

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
            -- todo: where should this code belong!!
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
