module Pages.EntityList exposing (..)

import Data.EntityListCursor as EntityListCursor exposing (EntityListCursor)
import Data.EntityListFilter exposing (..)
import Data.EntityTree
import Data.TodoDoc
import Document exposing (..)
import Entity exposing (..)
import GroupDoc exposing (..)
import List.Extra
import Maybe.Extra as Maybe
import Models.GroupDocStore exposing (..)
import Models.Stores
import Store
import Toolkit.Operators exposing (..)
import Tuple2
import X.Function exposing (..)
import X.List
import X.Predicate
import X.Record exposing (..)
import X.Return exposing (..)


type alias ModelRecord =
    { path : List String
    , namedFilterModel : NamedFilterModel
    , cursor : EntityListCursor
    }


type Model
    = Model ModelRecord


initialValue =
    pageModelConstructor defaultNamedFilterModel.pathPrefix
        defaultNamedFilterModel
        EntityListCursor.initialValue


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
    namedFilterTypeToFilter pageModel.namedFilterModel.namedFilterType pageModel.path


getNamedFilterModel =
    overModel .namedFilterModel


getMaybeLastKnownFocusedEntityId =
    get maybeEntityIdAtCursorFL


type Msg
    = MoveFocusBy Int
    | SetCursorEntityId EntityId


update config appModel msg =
    case msg of
        SetCursorEntityId entityId ->
            -- note: this is automatically called by focusIn event of list item.
            map (updateEntityListCursorWithMaybeEntityId appModel (entityId |> Just))

        MoveFocusBy offset ->
            moveFocusBy config offset appModel


overModel fn (Model model) =
    fn model


overModelF fn (Model model) =
    fn model |> Model


cursorFL =
    fieldLens (overModel .cursor) (\s b -> overModelF (\b -> { b | cursor = s }) b)


maybeEntityIdAtCursorFL =
    let
        maybeEntityIdAtCursorFL =
            fieldLens .maybeEntityIdAtCursor (\s b -> { b | maybeEntityIdAtCursor = s })
    in
    composeInnerOuterFieldLens maybeEntityIdAtCursorFL cursorFL


entityListCursorEntityIdListFL =
    let
        entityIdListFL =
            fieldLens .entityIdList (\s b -> { b | entityIdList = s })
    in
    composeInnerOuterFieldLens entityIdListFL cursorFL


updateEntityListCursorWithMaybeEntityId appModel maybeEntityIdAtCursor pageModel =
    let
        entityIdList =
            createEntityIdList appModel pageModel

        cursor =
            { entityIdList = entityIdList
            , maybeEntityIdAtCursor = maybeEntityIdAtCursor
            , filter = getFilter pageModel
            }
    in
    set cursorFL cursor pageModel


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
        (\pageModel ->
            let
                maybeLastKnownFocusedEntityId =
                    getMaybeLastKnownFocusedEntityId pageModel

                entityIdList =
                    get entityListCursorEntityIdListFL pageModel
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


createEntityIdList appModel pageModel =
    createEntityTree pageModel appModel
        |> Data.EntityTree.flatten
        .|> Entity.toEntityId


computeMaybeNewEntityIdAtCursor pageModel appModel =
    let
        newEntityIdList =
            createEntityIdList appModel pageModel

        computeMaybeFEI index =
            X.List.clampAndGetAtIndex index newEntityIdList

        computeNewEntityIdAtCursor entityIdAtCursor =
            ( get entityListCursorEntityIdListFL pageModel, newEntityIdList )
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
                getAndMaybeApply maybeEntityIdAtCursorFL computeNewEntityIdAtCursor pageModel
                    |> Maybe.join
            else
                get maybeEntityIdAtCursorFL pageModel
    in
    maybeCompute
        |> Maybe.orElseLazy (\_ -> List.head newEntityIdList)
