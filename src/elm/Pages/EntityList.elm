module Pages.EntityList exposing (..)

import Data.EntityListCursor as Cursor
import Data.EntityListFilter exposing (..)
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
    }


type Model
    = Model ModelRecord


initialValue =
    pageModelConstructor defaultNamedFilterModel.pathPrefix
        defaultNamedFilterModel
        Cursor.initialValue


pageModelConstructor path namedFilterModel cursor =
    ModelRecord path namedFilterModel cursor
        |> Model


maybeInitFromPath : List String -> Model -> Maybe Model
maybeInitFromPath path (Model pageModelRecord) =
    getMaybeNamedFilterModelFromPath path
        ?|> (pageModelConstructor path # pageModelRecord.cursor)


getFullPath (Model pageModel) =
    pageModel.path


getTitleColourTuple (Model pageModel) =
    pageModel.namedFilterModel |> (\model -> ( model.displayName, model.headerColor ))


getTitle (Model pageModel) =
    pageModel.namedFilterModel.displayName


getCursorFilter (Model pageModel) =
    pageModel.cursor.filter


getFilter (Model pageModel) =
    getFilterFromNamedFilterTypeAndPath pageModel.namedFilterModel.namedFilterType pageModel.path


getNamedFilterModel =
    overModel .namedFilterModel


getMaybeLastKnownFocusedEntityId =
    get maybeEntityIdAtCursorFL


type Msg
    = MoveFocusBy Int
    | SetCursorEntityId EntityId


pure model =
    model ! []


update config appModel msg pageModel =
    let
        dispatchMsg msg =
            update config appModel msg pageModel

        dispatchMaybeMsg msg =
            msg ?|> dispatchMsg ?= pure pageModel
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


overModel fn (Model model) =
    fn model


overModelF fn (Model model) =
    fn model |> Model


cursorFL =
    fieldLens (overModel .cursor) (\s b -> overModelF (\b -> { b | cursor = s }) b)


maybeEntityIdAtCursorFL =
    let
        maybeEntityIdAtCursorFL =
            fieldLens .maybeCursorEntityId (\s b -> { b | maybeCursorEntityId = s })
    in
    composeInnerOuterFieldLens maybeEntityIdAtCursorFL cursorFL


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

        FlatFilter flatFilterName ->
            let
                pred =
                    flatFilterNameToPredicate flatFilterName
            in
            Data.EntityTree.initTodoForest
                (getTitle pageModel)
                (filterTodosAndSortByLatestModified pred appModel)


flatFilterNameToPredicate filterType =
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
