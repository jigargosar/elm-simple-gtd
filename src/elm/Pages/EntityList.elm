module Pages.EntityList exposing (..)

import Data.EntityTree
import Data.NamedFilter exposing (..)
import Data.TodoDoc
import Document exposing (..)
import Entity exposing (..)
import GroupDoc exposing (..)
import List.Extra
import Maybe.Extra as Maybe
import Models.GroupDocStore exposing (..)
import Models.Selection
import Models.Stores
import Store
import Toolkit.Operators exposing (..)
import Tuple2
import X.Function exposing (..)
import X.List
import X.Predicate
import X.Record exposing (..)
import X.Return exposing (..)
import X.Set exposing (toggleSetMember)


type alias EntityListCursor =
    { entityIdList : List EntityId
    , maybeEntityIdAtCursor : Maybe EntityId
    , filter : Filter
    }


entityListCursorInitialValue : EntityListCursor
entityListCursorInitialValue =
    { entityIdList = []
    , maybeEntityIdAtCursor = Nothing
    , filter = GroupByFilter ContextGroupDocType
    }


type FlatFilterName
    = Done
    | Recent
    | Bin


type Filter
    = ContextIdFilter DocId
    | ProjectIdFilter DocId
    | FlatListFilter FlatFilterName
    | GroupByFilter GroupDocType


type alias PageModelRecord =
    { path : List String
    , namedFilterModel : NamedFilterModel
    , cursor : EntityListCursor
    }


type PageModel
    = PageModel PageModelRecord


defaultPageModel =
    pageModelConstructor defaultNamedFilterModel.pathPrefix
        defaultNamedFilterModel
        entityListCursorInitialValue


pageModelConstructor path namedFilterModel cursor =
    PageModelRecord path namedFilterModel cursor
        |> PageModel


initFromPath : List String -> Maybe PageModel
initFromPath path =
    getMaybeNamedFilterModelFromPath path
        ?|> (pageModelConstructor path # entityListCursorInitialValue)


getFullPath (PageModel pageModel) =
    pageModel.path


getTitleColourTuple (PageModel pageModel) =
    pageModel.namedFilterModel |> (\model -> ( model.displayName, model.headerColor ))


getTitle (PageModel pageModel) =
    pageModel.namedFilterModel.displayName


getCursorFilter (PageModel pageModel) =
    pageModel.cursor.filter


getFilter (PageModel pageModel) =
    case pageModel.namedFilterModel.namedFilterType of
        NF_WithNullContext ->
            ContextIdFilter ""

        NF_WithNullProject ->
            ProjectIdFilter ""

        NF_FL_Done ->
            FlatListFilter Done

        NF_FL_Recent ->
            FlatListFilter Recent

        NF_FL_Bin ->
            FlatListFilter Bin

        NF_GB_ActiveContexts ->
            GroupByFilter ContextGroupDocType

        NF_GB_ActiveProjects ->
            GroupByFilter ProjectGroupDocType

        NF_WithContextId_GB_Projects ->
            ContextIdFilter (List.Extra.last pageModel.path ?= "")

        NF_WithProjectId_GB_Contexts ->
            ProjectIdFilter (List.Extra.last pageModel.path ?= "")


getNamedFilterModel (PageModel pageModelRecord) =
    pageModelRecord.namedFilterModel


getMaybeLastKnownFocusedEntityId (PageModel pageModelRecord) =
    get maybeEntityIdAtCursorFL pageModelRecord


type Msg
    = MoveFocusBy Int
    | SetCursorEntityId EntityId


update config appModel msg =
    case msg of
        SetCursorEntityId entityId ->
            -- note: this is automatically called by focusIn event of list item.
            map (updateEntityListCursorWithMaybeEntityId config appModel (entityId |> Just))

        MoveFocusBy offset ->
            moveFocusBy config offset appModel


cursorFL =
    fieldLens .cursor (\s b -> { b | cursor = s })


maybeEntityIdAtCursorFL =
    let
        maybeEntityIdAtCursorFL =
            fieldLens .maybeEntityIdAtCursor (\s b -> { b | maybeEntityIdAtCursor = s })
    in
    composeInnerOuterFieldLens maybeEntityIdAtCursorFL cursorFL



--entityListCursorPageModelFL =
--    let
--        entityListPageModelFL =
--            fieldLens .entityListPageModel (\s b -> { b | entityListPageModel = s })
--    in
--    composeInnerOuterFieldLens entityListPageModelFL entityListCursorFL


entityListCursorEntityIdListFL =
    let
        entityIdListFL =
            fieldLens .entityIdList (\s b -> { b | entityIdList = s })
    in
    composeInnerOuterFieldLens entityIdListFL cursorFL


updateEntityListCursorWithMaybeEntityId config appModel maybeEntityIdAtCursor ((PageModel pageModelRecord) as pageModel) =
    let
        entityIdList =
            createEntityList pageModel appModel
                .|> Entity.toEntityId

        cursor =
            { entityIdList = entityIdList
            , maybeEntityIdAtCursor = maybeEntityIdAtCursor
            , filter = getFilter pageModel
            }
    in
    set cursorFL cursor pageModelRecord |> PageModel


moveFocusBy config offset appModel =
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
                |> Maybe.orElse (List.head entityIdList)
    in
    returnWithMaybe2 identity
        (\((PageModel pageModelRecord) as pageModel) ->
            let
                maybeLastKnownFocusedEntityId =
                    getMaybeLastKnownFocusedEntityId pageModel

                entityIdList =
                    get entityListCursorEntityIdListFL pageModelRecord
            in
            findEntityIdByOffsetIn offset
                entityIdList
                maybeLastKnownFocusedEntityId
                ?|> (SetCursorEntityId >> update config appModel)
        )


filterTodosAndSortBy pred sortBy model =
    Store.filterDocs pred model.todoStore
        |> List.sortBy sortBy


filterTodosAndSortByLatestCreated pred =
    filterTodosAndSortBy pred (Data.TodoDoc.getCreatedAt >> negate)


filterTodosAndSortByLatestModified pred =
    filterTodosAndSortBy pred (Data.TodoDoc.getModifiedAt >> negate)


getActiveTodoListForContext context model =
    filterTodosAndSortByLatestCreated
        (X.Predicate.all
            [ Data.TodoDoc.isActive
            , Data.TodoDoc.contextFilter context
            , Models.Stores.isTodoProjectActive model
            ]
        )
        model


getActiveTodoListForProject project model =
    filterTodosAndSortByLatestCreated
        (X.Predicate.all
            [ Data.TodoDoc.isActive
            , Data.TodoDoc.hasProject project
            , Models.Stores.isTodoContextActive model
            ]
        )
        model


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

        FlatListFilter flatFilterName ->
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
            X.Predicate.all [ Document.isNotDeleted, Data.TodoDoc.isDone ]

        Recent ->
            X.Predicate.always

        Bin ->
            Document.isDeleted


createEntityList pageModel appModel =
    createEntityTree pageModel appModel |> Data.EntityTree.flatten


computeMaybeNewEntityIdAtCursor ((PageModel pageModelRecord) as pageModel) appModel =
    let
        newEntityIdList =
            createEntityList pageModel appModel
                .|> Entity.toEntityId

        computeMaybeFEI index =
            X.List.clampAndGetAtIndex index newEntityIdList

        computeNewEntityIdAtCursor entityIdAtCursor =
            ( get entityListCursorEntityIdListFL pageModelRecord, newEntityIdList )
                |> Tuple2.mapBoth (X.List.firstIndexOf entityIdAtCursor)
                |> (\( maybeOldIndex, maybeNewIndex ) ->
                        case ( maybeOldIndex, maybeNewIndex, entityIdAtCursor ) of
                            ( Just oldIndex, Just newIndex, TodoEntityId _ ) ->
                                case compare oldIndex newIndex of
                                    LT ->
                                        computeMaybeFEI oldIndex

                                    GT ->
                                        computeMaybeFEI (oldIndex + 1)

                                    EQ ->
                                        Just entityIdAtCursor

                            ( Just oldIndex, Nothing, _ ) ->
                                computeMaybeFEI oldIndex

                            _ ->
                                Just entityIdAtCursor
                   )

        maybeCompute : Maybe EntityId
        maybeCompute =
            if getFilter pageModel == getCursorFilter pageModel then
                getAndMaybeApply maybeEntityIdAtCursorFL computeNewEntityIdAtCursor pageModelRecord
                    |> Maybe.join
            else
                get maybeEntityIdAtCursorFL pageModelRecord
    in
    maybeCompute
        |> Maybe.orElseLazy (\_ -> List.head newEntityIdList)
