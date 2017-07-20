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


type alias Config msg model =
    { onSetExclusiveMode : ExclusiveMode -> SubReturnF msg model
    , revertExclusiveMode : SubReturnF msg model
    , switchToEntityListView : EntityListViewType -> SubReturnF msg model
    , setDomFocusToFocusInEntityCmd : SubReturnF msg model
    , onStartEditingTodo : TodoDoc -> SubReturnF msg model
    }


update :
    Config msg model
    -> EntityMsg
    -> SubReturnF msg model
update config msg =
    case msg of
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
    Config msg model
    -> EntityId
    -> Entity.Types.EntityUpdateAction
    -> SubReturnF msg model
onUpdate config entityId action =
    case action of
        EUA_StartEditing ->
            startEditingEntity config entityId

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


startEditingEntity : Config msg model -> EntityId -> SubReturnF msg model
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
