module Update.Entity exposing (..)

import DomPorts
import Entity
import Entity.Types exposing (..)
import ExclusiveMode.Types exposing (..)
import GroupDoc.Form exposing (createAddGroupDocForm, createEditContextForm, createEditProjectForm)
import GroupDoc.Types exposing (GroupDocType(..))
import Keyboard.Extra as Key
import Maybe.Extra
import Model
import Model.GroupDocStore
import Model.Selection
import Model.TodoStore
import Model.ViewType
import Msg exposing (AppMsg)
import Return exposing (andThen, map)
import Set
import Stores
import Todo
import Todo.Msg
import Todo.Types exposing (TodoAction(..))
import TodoMsg
import Toolkit.Operators exposing (..)
import Types exposing (..)
import X.Record exposing (maybeOver)
import X.Return exposing (returnWith)
import Msg
import X.Function.Infix exposing (..)


update :
    (AppMsg -> ReturnF)
    -> Entity.Types.EntityMsg
    -> ReturnF
update andThenUpdate msg =
    case msg of
        EM_StartAddingContext ->
            (createAddGroupDocForm ContextGroupDoc
                |> XMGroupDocForm
                >> Msg.onSetExclusiveMode
                >> andThenUpdate
            )
                >> DomPorts.autoFocusInputRCmd

        EM_StartAddingProject ->
            (createAddGroupDocForm ProjectGroupDoc
                |> XMGroupDocForm
                >> Msg.onSetExclusiveMode
                >> andThenUpdate
            )
                >> DomPorts.autoFocusInputRCmd

        EM_Update entityId action ->
            onUpdate andThenUpdate entityId action

        EM_EntityListKeyDown entityList { key } ->
            case key of
                Key.ArrowUp ->
                    map (moveFocusBy -1 entityList)
                        >> andThenUpdate Model.setDomFocusToFocusInEntityCmd

                Key.ArrowDown ->
                    map (moveFocusBy 1 entityList)
                        >> andThenUpdate Model.setDomFocusToFocusInEntityCmd

                _ ->
                    identity


moveFocusBy : Int -> List Entity -> ModelF
moveFocusBy =
    Entity.findEntityByOffsetIn >>> maybeOver Model.focusInEntity


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
            X.Return.returnWith .editMode
                (\xMode ->
                    case xMode of
                        XMGroupDocForm form ->
                            GroupDoc.Form.setName newName form
                                |> XMGroupDocForm
                                >> Msg.onSetExclusiveMode
                                >> andThenUpdate

                        _ ->
                            identity
                )

        EUA_ToggleDeleted ->
            toggleDeleteEntity andThenUpdate entityId
                >> andThenUpdate Msg.revertExclusiveMode

        EUA_ToggleArchived ->
            let
                toggleArchivedEntity =
                    case entityId of
                        ContextId id ->
                            Msg.onToggleContextArchived id
                                |> andThenUpdate

                        ProjectId id ->
                            Msg.onToggleProjectArchived id
                                |> andThenUpdate

                        TodoId id ->
                            TodoMsg.onToggleDone id |> andThenUpdate
            in
                toggleArchivedEntity
                    >> andThenUpdate Msg.revertExclusiveMode

        EUA_OnFocusIn ->
            map (Stores.setFocusInEntityWithEntityId entityId)

        EUA_ToggleSelection ->
            map (toggleEntitySelection entityId)

        EUA_OnGotoEntity ->
            let
                switchToEntityListViewFromEntity entityId model =
                    let
                        maybeEntityListViewType =
                            Model.ViewType.maybeGetEntityListViewType model
                    in
                        entityId
                            |> toViewType model maybeEntityListViewType
                            |> Msg.switchToEntityListView
                            |> andThenUpdate
            in
                returnWith identity (switchToEntityListViewFromEntity entityId)


toggleEntitySelection entityId =
    Model.Selection.updateSelectedEntityIdSet (toggleSetMember (getDocIdFromEntityId entityId))


toggleSetMember item set =
    if Set.member item set then
        Set.remove item set
    else
        Set.insert item set



--toggleDeleteEntity : EntityId -> ModelReturnF


toggleDeleteEntity andThenUpdate entityId =
    case entityId of
        ContextId id ->
            Msg.onToggleContextDeleted id |> andThenUpdate

        ProjectId id ->
            Msg.onToggleProjectDeleted id |> andThenUpdate

        TodoId id ->
            TodoMsg.onToggleDeleted id |> andThenUpdate


startEditingEntity : (AppMsg -> ReturnF) -> EntityId -> ReturnF
startEditingEntity andThenUpdate entityId =
    case entityId of
        ContextId id ->
            X.Return.withMaybe
                (Model.GroupDocStore.findContextById id)
                (createEditContextForm >> XMGroupDocForm >> Msg.onSetExclusiveMode >> andThenUpdate)

        ProjectId id ->
            X.Return.withMaybe
                (Model.GroupDocStore.findProjectById id)
                (createEditProjectForm >> XMGroupDocForm >> Msg.onSetExclusiveMode >> andThenUpdate)

        TodoId id ->
            X.Return.withMaybe (Model.TodoStore.findTodoById id)
                (TodoMsg.onStartEditingTodo >> andThenUpdate)


toViewType : AppModel -> Maybe EntityListViewType -> EntityId -> EntityListViewType
toViewType appModel maybeCurrentEntityListViewType entityId =
    case entityId of
        ContextId id ->
            ContextView id

        ProjectId id ->
            ProjectView id

        TodoId id ->
            -- todo: where should this code belong? collaborate with todo and viewType
            let
                getViewTypeForTodo todo =
                    maybeCurrentEntityListViewType
                        ?|> getTodoGotoGroupView todo
                        ?= (Todo.getContextId todo |> ContextView)
            in
                Model.TodoStore.findTodoById id appModel
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
