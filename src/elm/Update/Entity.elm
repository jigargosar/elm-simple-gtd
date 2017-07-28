module Update.Entity exposing (Config, update)

import Entity
import Entity.Types exposing (..)
import EntityList exposing (HasEntityListCursor, entityListCursor)
import ExclusiveMode.Types exposing (..)
import GroupDoc.Types exposing (ContextStore, GroupDocType(..), ProjectStore)
import Keyboard.Extra as Key
import Lazy exposing (Lazy)
import List.Extra
import Maybe.Extra
import Model
import Model.EntityList
import Model.HasFocusInEntity exposing (HasFocusInEntity)
import Model.HasStores exposing (HasStores, HasViewType)
import Model.Selection
import Model.Stores
import Model.Todo
import Model.ViewType
import Return
import Set
import Time exposing (Time)
import Todo
import Todo.Types exposing (TodoDoc, TodoStore)
import Toolkit.Helpers exposing (..)
import Toolkit.Operators exposing (..)
import Tuple2
import ViewType exposing (ViewType)
import X.Function exposing (applyMaybeWith)
import X.Function.Infix exposing (..)
import X.List
import X.Record exposing (..)
import X.Return exposing (..)


type alias SubModel model =
    HasViewType
        (HasStores
            (HasEntityListCursor
                (HasFocusInEntity
                    { model
                        | selectedEntityIdSet : Set.Set String
                    }
                )
            )
        )


type alias SubModelF model =
    SubModel model -> SubModel model


type alias SubReturn msg model =
    Return msg (SubModel model)


type alias SubReturnF msg model =
    SubReturn msg model -> SubReturn msg model


type alias Config msg a =
    { a
        | onSetExclusiveMode : ExclusiveMode -> msg
        , revertExclusiveMode : msg
        , switchToEntityListViewTypeMsg : EntityListViewType -> msg
        , onStartEditingTodo : TodoDoc -> msg
        , currentViewEntityList : Lazy (List Entity)
    }


update :
    Config msg a
    -> EntityMsg
    -> SubReturnF msg model
update config msg =
    case msg of
        EM_UpdateEntityListCursor ->
            returnWith identity (updateEntityListCursor config)

        EM_SetFocusInEntity entity ->
            map (set Model.focusInEntity__ entity)
                >> map (setEntityListCursor (entity |> Entity.toEntityId >> Just))

        EM_SetFocusInEntityWithEntityId entityId ->
            returnWithMaybe1
                (Model.Stores.findByEntityId entityId)
                (EM_SetFocusInEntity >> update config)

        EM_Update entityId action ->
            onUpdateAction config entityId action

        EM_EntityListKeyDown entityList { key } ->
            let
                moveFocusBy offset =
                    returnWithMaybe2 Model.getFocusInEntity
                        (Entity.findEntityByOffsetIn offset entityList
                            >>? (EM_SetFocusInEntity >> update config)
                        )
            in
            case key of
                Key.ArrowUp ->
                    moveFocusBy -1

                Key.ArrowDown ->
                    moveFocusBy 1

                _ ->
                    identity



--updateEntityListCursor : SubModelF model


updateEntityListCursor config model =
    let
        computeMaybeFEI index =
            X.List.clampIndex index model.entityList.entityIdList
                |> X.List.atIndexIn model.entityList.entityIdList

        computeMaybeNextFEI oldIndex newIndex =
            case compare oldIndex newIndex of
                LT ->
                    computeMaybeFEI oldIndex

                GT ->
                    computeMaybeFEI (oldIndex + 1)

                EQ ->
                    Nothing

        getNewCursorEntityId : EntityId -> Maybe EntityId
        getNewCursorEntityId prevFocusableEntityId =
            let
                focusNextOnIndexChange =
                    True
            in
            ( model.entityList.prevEntityIdList
            , model.entityList.entityIdList
            )
                |> Tuple2.mapBoth
                    (X.List.firstIndexOf prevFocusableEntityId)
                |> (\maybeIndexT2 ->
                        --                        let
                        --                            _ =
                        --                                Debug.log "maybeIndexT2" maybeIndexT2
                        --                        in
                        case maybeIndexT2 of
                            ( Just oldIndex, Just newIndex ) ->
                                if focusNextOnIndexChange then
                                    computeMaybeNextFEI oldIndex newIndex
                                else
                                    Nothing

                            ( Just oldIndex, Nothing ) ->
                                computeMaybeFEI oldIndex

                            _ ->
                                Nothing
                   )

        updateHelp =
            model.entityList.prevMaybeFocusableEntityId
                ?+> (getNewCursorEntityId >>? (EM_SetFocusInEntityWithEntityId >> update config))
                ?= identity
    in
    if model.entityList.prevEntityIdList == model.entityList.entityIdList then
        identity
    else
        updateHelp


setEntityListCursor : Maybe EntityId -> SubModelF model
setEntityListCursor newMaybeFocusableEntityId model =
    let
        newEntityIdList =
            Model.EntityList.createEntityListForCurrentView model
                .|> Entity.toEntityId

        updateELI cursor =
            { entityIdList = newEntityIdList
            , maybeFocusableEntityId = newMaybeFocusableEntityId
            , prevEntityIdList = cursor.entityIdList
            , prevMaybeFocusableEntityId = cursor.maybeFocusableEntityId
            }
    in
    over
        entityListCursor
        updateELI
        model


onUpdateAction :
    Config msg a
    -> EntityId
    -> Entity.Types.EntityUpdateAction
    -> SubReturnF msg model
onUpdateAction config entityId action =
    case action of
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
                        |> config.switchToEntityListViewTypeMsg
                        |> returnMsgAsCmd
            in
            returnWith identity (switchToEntityListViewFromEntity entityId)

        EUA_BringEntityIdInView ->
            Lazy.force config.currentViewEntityList
                |> List.Extra.find (Entity.hasId entityId)
                |> Maybe.Extra.unpack
                    (\_ ->
                        returnMsgAsCmd (config.switchToEntityListViewTypeMsg ContextsView)
                            >> update config (EM_SetFocusInEntityWithEntityId entityId)
                    )
                    (EM_SetFocusInEntity >> update config)


toggleEntitySelection entityId =
    Model.Selection.updateSelectedEntityIdSet (toggleSetMember (getDocIdFromEntityId entityId))


toggleSetMember item set =
    if Set.member item set then
        Set.remove item set
    else
        Set.insert item set


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
