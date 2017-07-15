module Entity.Main exposing (..)

import Document
import DomPorts
import Entity.Types exposing (..)
import ExclusiveMode.Types exposing (..)
import GroupDoc
import GroupDoc.Form exposing (createAddGroupDocForm, createEditContextForm, createEditProjectForm)
import GroupDoc.Types exposing (GroupDocType(..))
import Maybe.Extra
import Model.Selection
import Model.ViewType
import Msg exposing (AppMsg)
import Return exposing (andThen)
import Set
import Stores
import Todo
import Todo.Msg
import Todo.Types exposing (TodoAction(..))
import TodoMsg
import Types exposing (AppModel, ModelF, ModelReturnF, ReturnF)
import Toolkit.Operators exposing (..)
import X.Return
import XMMsg


map =
    Return.map


update :
    (AppMsg -> ReturnF)
    -> Entity.Types.EntityMsg
    -> ReturnF
update andThenUpdate msg =
    case msg of
        EM_StartAddingContext ->
            (createAddGroupDocForm ContextGroupDoc
                |> XMGroupDocForm
                >> XMMsg.onSetExclusiveMode
                >> andThenUpdate
            )
                >> DomPorts.autoFocusInputRCmd

        EM_StartAddingProject ->
            (createAddGroupDocForm ProjectGroupDoc
                |> XMGroupDocForm
                >> XMMsg.onSetExclusiveMode
                >> andThenUpdate
            )
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
            X.Return.returnWith (.editMode)
                (\xMode ->
                    case xMode of
                        XMGroupDocForm form ->
                            GroupDoc.Form.setName newName form
                                |> XMGroupDocForm
                                >> XMMsg.onSetExclusiveMode
                                >> andThenUpdate

                        _ ->
                            identity
                )

        EUA_ToggleDeleted ->
            Return.andThen (toggleDeleteEntity entityId)
                >> andThenUpdate XMMsg.onSetExclusiveModeToNoneAndTryRevertingFocus

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
                    >> andThenUpdate XMMsg.onSetExclusiveModeToNoneAndTryRevertingFocus

        EUA_OnFocusIn ->
            Return.map (Stores.setFocusInEntityWithEntityId entityId)

        EUA_ToggleSelection ->
            Return.map (toggleEntitySelection entityId)

        EUA_OnGotoEntity ->
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
            X.Return.withMaybe
                (Stores.findContextById id)
                (createEditContextForm >> XMGroupDocForm >> XMMsg.onSetExclusiveMode >> andThenUpdate)

        ProjectId id ->
            X.Return.withMaybe
                (Stores.findProjectById id)
                (createEditProjectForm >> XMGroupDocForm >> XMMsg.onSetExclusiveMode >> andThenUpdate)

        TodoId id ->
            X.Return.withMaybe (Stores.findTodoById id)
                (TodoMsg.onStartEditingTodo >> andThenUpdate)


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
