module Pages.EntityList exposing (..)

import Data.EntityListCursor as Cursor
import Data.EntityListFilter as Filter
    exposing
        ( Filter(..)
        , FlatFilterType(..)
        , NamedFilterModel
        , NamedFilterType(..)
        )
import Data.EntityTree
import Data.TodoDoc as TodoDoc
import Document exposing (..)
import Entity exposing (..)
import GroupDoc exposing (..)
import Models.GroupDocStore exposing (..)
import Set
import Store
import Toolkit.Operators exposing (..)
import X.Predicate
import X.Record exposing (..)


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
    ModelRecord path
        namedFilterModel
        cursor
        (Filter.getFilterFromNamedFilterTypeAndPath namedFilterModel.namedFilterType path)
        |> Model


initialValue =
    let
        ({ pathPrefix } as namedFilterModel) =
            Filter.initialNamedFilterModel

        filter =
            GroupByFilter ContextGroupDocType

        cursor =
            Cursor.initialValue filter
    in
    constructor pathPrefix namedFilterModel cursor


maybeInitFromPath : List String -> Model -> Maybe Model
maybeInitFromPath path (Model model) =
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


type Msg
    = MoveFocusBy Int
    | SetCursorEntityId EntityId
    | SetCursorEntityIdAndDomFocus EntityId
    | RecomputeEntityListCursorAfterChangesReceivedFromPouchDBMsg


pure model =
    model ! []


update config appModel msg pageModel =
    let
        dispatchMsg msg =
            update config appModel msg pageModel

        dispatchMaybeMsg msg =
            msg ?|> dispatchMsg ?= pure pageModel

        noop =
            pure pageModel
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

        SetCursorEntityIdAndDomFocus entityId ->
            noop

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
                        let
                            _ =
                                Debug.log "UpdateEntityListCursor Called " entityId
                        in
                        SetCursorEntityIdAndDomFocus entityId
                    )
                |> dispatchMaybeMsg


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


filterTodosAndSortBy pred sortBy model =
    Store.filterDocs pred model.todoStore
        |> List.sortBy sortBy


filterTodosAndSortByLatestCreated pred =
    filterTodosAndSortBy pred (TodoDoc.getCreatedAt >> negate)


filterTodosAndSortByLatestModified pred =
    filterTodosAndSortBy pred (TodoDoc.getModifiedAt >> negate)


getActiveTodoListForContext context appModel =
    let
        activeProjectIdSet =
            Models.GroupDocStore.getActiveProjects appModel
                .|> Document.getId
                |> Set.fromList

        isTodoProjectActive =
            TodoDoc.getProjectId >> Set.member # activeProjectIdSet
    in
    filterTodosAndSortByLatestCreated
        (X.Predicate.all
            [ TodoDoc.isActive
            , TodoDoc.contextFilter context
            , isTodoProjectActive
            ]
        )
        appModel


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
                |> Data.EntityTree.initContextRoot
                    getActiveTodoListForContextHelp
                    findProjectByIdHelp

        ProjectIdFilter id ->
            Models.GroupDocStore.findProjectById id appModel
                ?= GroupDoc.nullProject
                |> Data.EntityTree.initProjectRoot
                    getActiveTodoListForProjectHelp
                    findContextByIdHelp

        GroupByFilter groupDocType ->
            case groupDocType of
                ContextGroupDocType ->
                    Models.GroupDocStore.getActiveContexts appModel
                        |> Data.EntityTree.initContextForest
                            getActiveTodoListForContextHelp

                ProjectGroupDocType ->
                    Models.GroupDocStore.getActiveProjects appModel
                        |> Data.EntityTree.initProjectForest
                            getActiveTodoListForProjectHelp

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
            Data.EntityTree.initTodoForest
                (getTitle pageModel)
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
        |> Data.EntityTree.flatten
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
