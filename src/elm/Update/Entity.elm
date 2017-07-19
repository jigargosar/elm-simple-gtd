module Update.Entity exposing (Config, update)

import Document.Types exposing (DocId)
import DomPorts
import Entity
import Entity.Types exposing (..)
import ExclusiveMode.Types exposing (..)
import GroupDoc.Form exposing (createAddGroupDocForm, createEditContextForm, createEditProjectForm)
import GroupDoc.Types exposing (ContextStore, GroupDocType(..), ProjectStore)
import Keyboard.Extra as Key
import Maybe.Extra
import Model
import Model.GroupDocStore
import Model.Selection
import Model.Stores
import Model.Todo
import Model.ViewType
import Return exposing (andThen, map)
import Set
import Time exposing (Time)
import Todo
import Todo.Types exposing (TodoDoc, TodoStore)
import Toolkit.Operators exposing (..)
import Types.ViewType exposing (ViewType)
import X.Record exposing (maybeOver)
import X.Return exposing (returnWith)
import X.Function.Infix exposing (..)


type alias SubModel model =
    { model
        | contextStore : ContextStore
        , editMode : ExclusiveMode
        , focusInEntity : Entity
        , now : Time
        , projectStore : ProjectStore
        , todoStore : TodoStore
        , viewType : ViewType
        , selectedEntityIdSet : Set.Set String
    }


type alias SubModelF model =
    SubModel model -> SubModel model


type alias SubReturn msg model =
    Return.Return msg (SubModel model)


type alias SubReturnF msg model =
    SubReturn msg model -> SubReturn msg model


type alias Config a msg model =
    { a
        | onSetExclusiveMode : ExclusiveMode -> SubReturnF msg model
        , revertExclusiveMode : SubReturnF msg model
        , onToggleContextArchived : DocId -> SubReturnF msg model
        , onToggleContextDeleted : DocId -> SubReturnF msg model
        , onToggleProjectArchived : DocId -> SubReturnF msg model
        , onToggleProjectDeleted : DocId -> SubReturnF msg model
        , onToggleTodoArchived : DocId -> SubReturnF msg model
        , onToggleTodoDeleted : DocId -> SubReturnF msg model
        , switchToEntityListView : EntityListViewType -> SubReturnF msg model
        , setDomFocusToFocusInEntityCmd : SubReturnF msg model
        , onStartEditingTodo : TodoDoc -> SubReturnF msg model
    }


update :
    Config a msg model
    -> EntityMsg
    -> SubReturnF msg model
update config msg =
    case msg of
        EM_StartAddingContext ->
            (createAddGroupDocForm ContextGroupDoc
                |> XMGroupDocForm
                >> config.onSetExclusiveMode
            )
                >> DomPorts.autoFocusInputRCmd

        EM_StartAddingProject ->
            (createAddGroupDocForm ProjectGroupDoc
                |> XMGroupDocForm
                >> config.onSetExclusiveMode
            )
                >> DomPorts.autoFocusInputRCmd

        EM_Update entityId action ->
            onUpdate config entityId action

        EM_EntityListKeyDown entityList { key } ->
            case key of
                Key.ArrowUp ->
                    map (moveFocusBy -1 entityList)
                        >> config.setDomFocusToFocusInEntityCmd

                Key.ArrowDown ->
                    map (moveFocusBy 1 entityList)
                        >> config.setDomFocusToFocusInEntityCmd

                _ ->
                    identity


moveFocusBy : Int -> List Entity -> SubModelF model
moveFocusBy =
    Entity.findEntityByOffsetIn >>> maybeOver Model.focusInEntity


onUpdate :
    Config a msg model
    -> EntityId
    -> Entity.Types.EntityUpdateAction
    -> SubReturnF msg model
onUpdate config entityId action =
    case action of
        EUA_StartEditing ->
            startEditingEntity config entityId
                >> DomPorts.autoFocusInputRCmd

        EUA_SetFormText newName ->
            X.Return.returnWith .editMode
                (\xMode ->
                    case xMode of
                        XMGroupDocForm form ->
                            GroupDoc.Form.setName newName form
                                |> XMGroupDocForm
                                >> config.onSetExclusiveMode

                        _ ->
                            identity
                )

        EUA_ToggleDeleted ->
            toggleDeleteEntity config entityId >> config.revertExclusiveMode

        EUA_ToggleArchived ->
            let
                toggleArchivedEntity =
                    case entityId of
                        ContextId id ->
                            config.onToggleContextArchived id

                        ProjectId id ->
                            config.onToggleProjectArchived id

                        TodoId id ->
                            config.onToggleTodoArchived id
            in
                toggleArchivedEntity
                    >> config.revertExclusiveMode

        EUA_OnFocusIn ->
            map (Model.Stores.setFocusInEntityWithEntityId entityId)

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
                            |> config.switchToEntityListView
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


toggleDeleteEntity config entityId =
    case entityId of
        ContextId id ->
            config.onToggleContextDeleted id

        ProjectId id ->
            config.onToggleProjectDeleted id

        TodoId id ->
            config.onToggleTodoDeleted id


startEditingEntity : Config a msg model -> EntityId -> SubReturnF msg model
startEditingEntity config entityId =
    case entityId of
        ContextId id ->
            X.Return.returnWithMaybe1
                (Model.GroupDocStore.findContextById id)
                (createEditContextForm >> XMGroupDocForm >> config.onSetExclusiveMode)

        ProjectId id ->
            X.Return.returnWithMaybe1
                (Model.GroupDocStore.findProjectById id)
                (createEditProjectForm >> XMGroupDocForm >> config.onSetExclusiveMode)

        TodoId id ->
            X.Return.returnWithMaybe1 (Model.Todo.findTodoById id)
                (config.onStartEditingTodo)


toViewType : SubModel model -> Maybe EntityListViewType -> EntityId -> EntityListViewType
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
                Model.Todo.findTodoById id appModel
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
