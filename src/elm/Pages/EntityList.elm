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
import Data.EntityTree as Tree
import Data.TodoDoc as TodoDoc
import Document exposing (..)
import Entity exposing (..)
import GroupDoc exposing (..)
import Models.GroupDocStore exposing (..)
import Ports
import Set
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


getActiveTodoListForContext context appModel =
    let
        activeProjectIdSet =
            Models.GroupDocStore.getActiveProjectIdSet appModel

        isTodoProjectActive =
            TodoDoc.getProjectId >> Set.member # activeProjectIdSet

        pred =
            X.Predicate.all
                [ TodoDoc.isActive
                , TodoDoc.contextFilter context
                , isTodoProjectActive
                ]
    in
    filterTodosAndSortByLatestCreated pred appModel


getActiveTodoListForProject project appModel =
    let
        activeContextIdSet =
            Models.GroupDocStore.getActiveContexts appModel
                .|> Document.getId
                |> Set.fromList

        isTodoContextActive =
            TodoDoc.getContextId >> Set.member # activeContextIdSet
    in
    filterTodosAndSortByLatestCreated
        (X.Predicate.all
            [ TodoDoc.isActive
            , TodoDoc.hasProject project
            , isTodoContextActive
            ]
        )
        appModel


createEntityTree pageModel appModel =
    let
        getActiveTodoListForContextHelp =
            getActiveTodoListForContext # appModel

        getActiveTodoListForProjectHelp =
            getActiveTodoListForProject # appModel

        findProjectByIdHelp =
            Models.GroupDocStore.findProjectById # appModel

        findContextByIdHelp =
            Models.GroupDocStore.findContextById # appModel
    in
    case getFilter pageModel of
        ContextIdFilter id ->
            Models.GroupDocStore.findContextById id appModel
                ?= GroupDoc.nullContext
                |> Tree.initContextRoot
                    getActiveTodoListForContextHelp
                    findProjectByIdHelp

        ProjectIdFilter id ->
            Models.GroupDocStore.findProjectById id appModel
                ?= GroupDoc.nullProject
                |> Tree.initProjectRoot
                    getActiveTodoListForProjectHelp
                    findContextByIdHelp

        GroupByFilter groupByType ->
            case groupByType of
                ActiveGroupDocList ContextGroupDocType ->
                    Models.GroupDocStore.getActiveContexts appModel
                        |> Tree.initContextForest
                            getActiveTodoListForContextHelp

                ActiveGroupDocList ProjectGroupDocType ->
                    Models.GroupDocStore.getActiveProjects appModel
                        |> Tree.initProjectForest
                            getActiveTodoListForProjectHelp

                SingleGroupDoc groupDocId ->
                    Tree.createRootWithStringTitle (getTitle pageModel)
                        []
                        0

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
            Tree.createRootWithStringTitle (getTitle pageModel)
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
