module Update.Entity exposing (Config, update)

import Entity
import Entity.Tree
import Entity.Types exposing (..)
import EntityListCursor exposing (..)
import ExclusiveMode.Types exposing (..)
import List.Extra
import Maybe.Extra
import Models.EntityTree
import Models.HasStores exposing (HasPage, HasStores)
import Models.Selection
import Models.Todo
import Page
import Pages.EntityListOld exposing (..)
import Set
import Todo
import Toolkit.Operators exposing (..)
import Tuple2
import Types.Todo exposing (..)
import X.Function exposing (..)
import X.Function.Infix exposing (..)
import X.List
import X.Record exposing (..)
import X.Return exposing (..)


type alias SubModel model =
    HasPage
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
        , gotoEntityListPageMsg : Old_EntityListPageModel -> msg
        , onStartEditingTodo : TodoDoc -> msg
        , maybeEntityListPageModel : Maybe Old_EntityListPageModel
    }


update :
    Config msg a
    -> EntityMsg
    -> SubReturnF msg model
update config msg =
    case msg of
        EM_SetFocusInEntityWithEntityId entityId ->
            map (setEntityAtCursor config (entityId |> Just))

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
                maybeEntityIdAtCursorOld =
                    EntityListCursor.computeMaybeNewEntityIdAtCursorOld config.maybeEntityListPageModel model

                entityIdList =
                    createEntityListFormMaybeEntityListPageModelOld config.maybeEntityListPageModel model
                        .|> Entity.toEntityId
            in
            findEntityIdByOffsetIn offset
                entityIdList
                maybeEntityIdAtCursorOld
                ?|> (EM_SetFocusInEntityWithEntityId >> update config)
        )


entityListCursor =
    fieldLens .entityListCursor (\s b -> { b | entityListCursor = s })


setEntityAtCursor : Config msg a -> Maybe EntityId -> SubModelF model
setEntityAtCursor config maybeEntityIdAtCursorOld model =
    let
        entityIdList =
            createEntityListFormMaybeEntityListPageModelOld config.maybeEntityListPageModel model
                .|> Entity.toEntityId

        cursor =
            { entityIdList = entityIdList
            , maybeEntityIdAtCursor = maybeEntityIdAtCursorOld
            }
    in
    setIn model entityListCursor cursor


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
                        maybeEntityListPageModel =
                            Page.maybeGetEntityListPage model
                    in
                    entityId
                        |> toPage model maybeEntityListPageModel
                        |> config.gotoEntityListPageMsg
                        |> returnMsgAsCmd
            in
            returnWith identity (switchToEntityListViewFromEntity entityId)

        EUA_BringEntityIdInView ->
            returnWith (createEntityListFormMaybeEntityListPageModelOld config.maybeEntityListPageModel)
                (List.Extra.find (Entity.hasId entityId)
                    >> Maybe.Extra.unpack
                        (\_ ->
                            returnMsgAsCmd (config.gotoEntityListPageMsg ContextsView)
                                >> update config (EM_SetFocusInEntityWithEntityId entityId)
                        )
                        (Entity.toEntityId
                            >> EM_SetFocusInEntityWithEntityId
                            >> update config
                        )
                )


toggleEntitySelection entityId =
    Models.Selection.updateSelectedEntityIdSet (toggleSetMember (getDocIdFromEntityId entityId))


toggleSetMember item set =
    if Set.member item set then
        Set.remove item set
    else
        Set.insert item set


toPage : SubModel model -> Maybe Old_EntityListPageModel -> EntityId -> Old_EntityListPageModel
toPage appModel maybeCurrentEntityListPage entityId =
    case entityId of
        ContextId id ->
            ContextView id

        ProjectId id ->
            ProjectView id

        TodoId id ->
            let
                getPageForTodo todo =
                    maybeCurrentEntityListPage
                        ?|> getTodoGotoGroupView todo
                        ?= (Todo.getContextId todo |> ContextView)
            in
            Models.Todo.findTodoById id appModel
                ?|> getPageForTodo
                |> Maybe.Extra.orElse maybeCurrentEntityListPage
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
