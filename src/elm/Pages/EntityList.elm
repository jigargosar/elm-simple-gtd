module Pages.EntityList exposing (..)

import Data.EntityListCursor as Cursor
import Data.EntityListFilter as Filter
    exposing
        ( Filter(..)
        , FlatFilterType(..)
        , GroupByType(..)
        , NamedFilterModel
        , NamedFilterType(..)
        )
import Data.EntityTree as Tree exposing (GroupDocNode(..), Tree)
import Data.TodoDoc as TodoDoc exposing (TodoDoc)
import Document exposing (..)
import Entity exposing (..)
import GroupDoc exposing (..)
import List.Extra
import Models.GroupDocStore as GroupDocStore
import Ports
import Set exposing (Set)
import Store
import Toolkit.Operators exposing (..)
import X.Predicate
import X.Record exposing (..)
import X.Return exposing (..)


type alias ModelRecord =
    { path : List String
    , namedFilterModel : NamedFilterModel
    , cursor : Cursor.Model
    , filter : Filter
    }


type Model
    = Model ModelRecord


constructor : List String -> NamedFilterModel -> Cursor.Model -> Model
constructor path namedFilterModel cursor =
    let
        filter =
            Filter.getFilterFromNamedFilterTypeAndPath namedFilterModel.namedFilterType path
    in
    ModelRecord path
        namedFilterModel
        cursor
        -- (Cursor.initialValue filter)
        filter
        |> Model


initialValue =
    let
        ({ pathPrefix } as namedFilterModel) =
            Filter.initialNamedFilterModel

        filter =
            GroupByFilter (ActiveGroupDocList ContextGroupDocType)

        cursor =
            Cursor.initialValue filter
    in
    constructor pathPrefix namedFilterModel cursor


maybeInitFromPath : List String -> Maybe Model -> Maybe Model
maybeInitFromPath path maybeModel =
    let
        (Model model) =
            maybeModel ?= initialValue
    in
    Filter.getMaybeNamedFilterModelFromPath path
        ?|> (\namedFilterModel ->
                constructor path
                    namedFilterModel
                    model.cursor
            )


getFullPath (Model pageModel) =
    pageModel.path


getTitleColourTuple (Model pageModel) =
    pageModel.namedFilterModel |> (\model -> ( model.displayName, model.headerColor ))


getTitle (Model pageModel) =
    pageModel.namedFilterModel.displayName


getFilter (Model pageModel) =
    Filter.getFilterFromNamedFilterTypeAndPath pageModel.namedFilterModel.namedFilterType pageModel.path


getMaybeLastKnownFocusedEntityId : Model -> Maybe EntityId
getMaybeLastKnownFocusedEntityId =
    get cursorFL >> .maybeCursorEntityId


getEntityListDomIdFromEntityId entityId =
    case entityId of
        ContextEntityId docId ->
            "entity-list-context-id-" ++ docId

        ProjectEntityId docId ->
            "entity-list-project-id-" ++ docId

        TodoEntityId docId ->
            "entity-list-todo-id-" ++ docId


type Msg
    = MoveFocusBy Int
    | SetCursorEntityId EntityId
    | RecomputeEntityListCursorAfterChangesReceivedFromPouchDBMsg
    | GoToEntityId EntityId


update config appModel msg pageModel =
    let
        noop =
            pure pageModel

        dispatchMsg msg =
            update config appModel msg pageModel

        dispatchMaybeMsg msg =
            msg ?|> dispatchMsg ?= noop
    in
    case msg of
        SetCursorEntityId entityId ->
            -- note: this is automatically called by focusIn event of list item.
            let
                entityIdList =
                    createEntityIdList appModel pageModel

                cursor =
                    Cursor.create entityIdList
                        (Just entityId)
                        (getFilter pageModel)
            in
            set cursorFL cursor pageModel |> pure

        MoveFocusBy offset ->
            let
                cursor =
                    get cursorFL pageModel
            in
            Cursor.findEntityIdByOffsetIndex offset cursor
                ?|> SetCursorEntityId
                |> dispatchMaybeMsg

        RecomputeEntityListCursorAfterChangesReceivedFromPouchDBMsg ->
            computeMaybeNewEntityIdAtCursor appModel pageModel
                ?|> (\entityId ->
                        ( pageModel
                        , Ports.focusSelector ("#" ++ getEntityListDomIdFromEntityId entityId)
                        )
                    )
                ?= noop

        GoToEntityId entityId ->
            let
                _ =
                    --config.navigateToPath
                    1
            in
            noop


overModel fn (Model model) =
    fn model


overModelF fn (Model model) =
    fn model |> Model


cursorFL =
    fieldLens (overModel .cursor) (\s b -> overModelF (\b -> { b | cursor = s }) b)


entityListCursorEntityIdListFL =
    let
        entityIdListFL =
            fieldLens .entityIdList (\s b -> { b | entityIdList = s })
    in
    composeInnerOuterFieldLens entityIdListFL cursorFL


filterTodoDocs pred model =
    Store.filterDocs pred model.todoStore


filterTodosAndSortBy pred sortBy model =
    filterTodoDocs pred model
        |> List.sortBy sortBy


filterTodosAndSortByLatestCreated pred =
    filterTodosAndSortBy pred (TodoDoc.getCreatedAt >> negate)


filterTodosAndSortByLatestModified pred =
    filterTodosAndSortBy pred (TodoDoc.getModifiedAt >> negate)


activeTodoListPredicateForGroupDocId groupDocId =
    X.Predicate.all
        [ TodoDoc.isActive
        , TodoDoc.hasGroupDocId groupDocId
        ]


getActiveTodoListForGroupDoc gdType groupDoc appModel =
    let
        secondaryGDType =
            computeSecondaryGroupDocType gdType

        groupDocId =
            GroupDoc.idFromDoc gdType groupDoc

        activeSecondaryGroupDocIdSet =
            GroupDocStore.getActiveDocIdSet secondaryGDType appModel

        isTodoSecondaryGroupDocActive =
            TodoDoc.hasGroupDocIdInSet secondaryGDType activeSecondaryGroupDocIdSet

        pred =
            X.Predicate.all
                [ activeTodoListPredicateForGroupDocId groupDocId
                , isTodoSecondaryGroupDocActive
                ]
    in
    filterTodosAndSortByLatestCreated pred appModel


computeSecondaryGroupDocType gdType =
    case gdType of
        ContextGroupDocType ->
            ProjectGroupDocType

        ProjectGroupDocType ->
            ContextGroupDocType


getActiveTodoListForGroupDocEntity (GroupDocEntity gdType groupDoc) =
    getActiveTodoListForGroupDoc gdType groupDoc


createActiveGroupDocForest gdType appModel =
    let
        activeGroupDocEntityList =
            GroupDocStore.getActiveDocs gdType appModel
                .|> Entity.createGroupDocEntity gdType

        createNode : GroupDocEntity -> GroupDocNode
        createNode groupDocEntity =
            let
                todoList =
                    getActiveTodoListForGroupDocEntity groupDocEntity appModel
            in
            Tree.createGroupDocEntityNode groupDocEntity
                todoList
    in
    activeGroupDocEntityList
        .|> createNode
        |> Tree.createForest


createGroupDocTree gdType docId appModel =
    let
        gDoc =
            let
                groupDocId =
                    GroupDoc.createId gdType docId
            in
            GroupDocStore.findByGroupDocIdOrNull groupDocId appModel

        groupDocEntity =
            Entity.createGroupDocEntity gdType gDoc

        todoList =
            -- use Id we do not need entity
            getActiveTodoListForGroupDocEntity groupDocEntity appModel

        secondaryGDType =
            computeSecondaryGroupDocType gdType

        todoListToUniqueGroupDocIdList : GroupDocType -> List TodoDoc -> List GroupDocId
        todoListToUniqueGroupDocIdList gdType todoList =
            todoList
                .|> TodoDoc.getGroupDocId gdType
                |> List.Extra.uniqueBy GroupDoc.toComparable

        secondaryGDList =
            let
                isNull =
                    GroupDoc.isNull secondaryGDType

                findByGroupDocId groupDocId =
                    GroupDocStore.findByGroupDocId groupDocId appModel
            in
            todoList
                |> todoListToUniqueGroupDocIdList secondaryGDType
                .|> findByGroupDocId
                |> List.filterMap identity
                |> GroupDoc.sortWithIsNull isNull

        nodeList =
            let
                idFromDoc doc =
                    GroupDoc.idFromDoc secondaryGDType doc

                createEntity gDoc =
                    Entity.createGroupDocEntity secondaryGDType gDoc

                filterTodoList gDoc =
                    List.filter (TodoDoc.hasGroupDocId (idFromDoc gDoc)) todoList

                createGroupDocEntityNode gDoc =
                    Tree.createGroupDocEntityNode
                        (createEntity gDoc)
                        (filterTodoList gDoc)
            in
            secondaryGDList .|> createGroupDocEntityNode
    in
    Tree.createGroupDocTree groupDocEntity todoList nodeList


createEntityTree pageModel appModel =
    case getFilter pageModel of
        GroupByFilter groupByType ->
            case groupByType of
                ActiveGroupDocList gdType ->
                    createActiveGroupDocForest gdType appModel

                SingleGroupDoc gdType docId ->
                    createGroupDocTree gdType docId appModel

        FlatFilter flatFilterType maxDisplayCount ->
            let
                pred =
                    flatFilterTypeToPredicate flatFilterType

                todoList =
                    filterTodosAndSortByLatestModified pred appModel

                totalCount =
                    List.length todoList

                truncatedTodoList =
                    List.take maxDisplayCount todoList
            in
            Tree.createFlatTodoListNode (getTitle pageModel)
                truncatedTodoList
                totalCount


flatFilterTypeToPredicate filterType =
    case filterType of
        Done ->
            X.Predicate.all [ Document.isNotDeleted, TodoDoc.isDone ]

        Recent ->
            X.Predicate.always

        Bin ->
            Document.isDeleted


createEntityIdList appModel pageModel =
    createEntityTree pageModel appModel
        |> Tree.flatten
        .|> Entity.toEntityId


computeMaybeNewEntityIdAtCursor appModel pageModel =
    let
        newEntityIdList =
            createEntityIdList appModel pageModel

        newFilter =
            getFilter pageModel
    in
    get cursorFL pageModel
        |> Cursor.computeNewEntityIdAtCursor newFilter newEntityIdList
