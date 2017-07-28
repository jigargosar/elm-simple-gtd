module Update.Entity exposing (Config, update)

import Entity
import Entity.Tree
import Entity.Types exposing (..)
import EntityListCursor exposing (..)
import ExclusiveMode.Types exposing (..)
import Keyboard.Extra as Key
import List.Extra
import Maybe.Extra
import Model
import Model.EntityTree
import Model.HasStores exposing (HasStores, HasViewType)
import Model.Selection
import Model.Stores
import Model.Todo
import Model.ViewType
import Set
import Todo
import Todo.Types exposing (TodoDoc, TodoStore)
import Toolkit.Operators exposing (..)
import Tuple2
import X.Function exposing (..)
import X.Function.Infix exposing (..)
import X.List
import X.Record exposing (..)
import X.Return exposing (..)


type alias SubModel model =
    HasViewType
        (HasStores
            (HasEntityListCursor
                { model
                    | selectedEntityIdSet : Set.Set String
                }
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
            map (setEntityAtCursor (entity |> Entity.toEntityId >> Just))

        EM_SetFocusInEntityWithEntityId entityId ->
            returnWithMaybe1
                (Model.Stores.findByEntityId entityId)
                (EM_SetFocusInEntity >> update config)

        EM_Update entityId action ->
            onUpdateAction config entityId action

        EM_EntityListFocusPrev ->
            moveFocusBy config -1

        EM_EntityListFocusNext ->
            moveFocusBy config 1


moveFocusBy config offset =
    let
        findEntityIdByOffsetIn offsetIndex entityIdList maybeOffsetFromEntityId =
            let
                index =
                    maybeOffsetFromEntityId
                        ?+> (equals >> X.List.findIndexIn entityIdList)
                        ?= 0
                        |> add offsetIndex
            in
            X.List.clampAndGetAtIndex index entityIdList
                |> Maybe.Extra.orElse (List.head entityIdList)
    in
    returnWithMaybe2 identity
        (\model ->
            let
                maybeEntityIdAtCursor =
                    EntityListCursor.getMaybeEntityIdAtCursor model

                entityIdList =
                    createEntityListForCurrentView model
                        .|> Entity.toEntityId
            in
            findEntityIdByOffsetIn offset
                entityIdList
                maybeEntityIdAtCursor
                ?|> (EM_SetFocusInEntityWithEntityId >> update config)
        )


updateEntityListCursor : Config msg a -> SubModel model -> SubReturnF msg model
updateEntityListCursor config model =
    let
        newEntityIdList =
            createEntityListForCurrentView model
                .|> Entity.toEntityId

        computeMaybeFEI index =
            X.List.clampAndGetAtIndex index newEntityIdList

        computeNewEntityIdAtCursor : EntityId -> Maybe EntityId
        computeNewEntityIdAtCursor focusableEntityId =
            ( model.entityListCursor.entityIdList, newEntityIdList )
                |> Tuple2.mapBoth (X.List.firstIndexOf focusableEntityId)
                |> (\( maybeOldIndex, maybeNewIndex ) ->
                        case ( maybeOldIndex, maybeNewIndex, focusableEntityId ) of
                            ( Just oldIndex, Just newIndex, TodoId _ ) ->
                                case compare oldIndex newIndex of
                                    LT ->
                                        computeMaybeFEI oldIndex

                                    GT ->
                                        computeMaybeFEI (oldIndex + 1)

                                    EQ ->
                                        Nothing

                            ( Just oldIndex, Nothing, _ ) ->
                                computeMaybeFEI oldIndex

                            _ ->
                                Nothing
                   )
    in
    model.entityListCursor.maybeEntityIdAtCursor
        ?+> computeNewEntityIdAtCursor
        >>? (EM_SetFocusInEntityWithEntityId >> update config)
        ?= identity


entityListCursor =
    fieldLens .entityListCursor (\s b -> { b | entityListCursor = s })


setEntityAtCursor : Maybe EntityId -> SubModelF model
setEntityAtCursor maybeEntityIdAtCursor model =
    let
        entityIdList =
            createEntityListForCurrentView model
                .|> Entity.toEntityId

        cursor =
            { entityIdList = entityIdList
            , maybeEntityIdAtCursor = maybeEntityIdAtCursor
            }
    in
    setIn model entityListCursor cursor


createEntityListForCurrentView model =
    Model.ViewType.maybeGetEntityListViewType model
        ?|> (Model.EntityTree.createEntityTreeForViewType # model >> Entity.Tree.flatten)
        ?= []


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
            returnWith createEntityListForCurrentView
                (List.Extra.find (Entity.hasId entityId)
                    >> Maybe.Extra.unpack
                        (\_ ->
                            returnMsgAsCmd (config.switchToEntityListViewTypeMsg ContextsView)
                                >> update config (EM_SetFocusInEntityWithEntityId entityId)
                        )
                        (EM_SetFocusInEntity >> update config)
                )


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
