module Pages.EntityList exposing (..)

import Data.EntityListCursor as EntityListCursor
import Data.EntityListFilter exposing (..)
import Data.EntityTree
import Data.TodoDoc as TodoDoc
import Document exposing (..)
import Entity exposing (..)
import GroupDoc exposing (..)
import List.Extra
import Maybe.Extra as Maybe
import Models.GroupDocStore exposing (..)
import Models.Stores
import Set
import Store
import Toolkit.Helpers exposing (..)
import Toolkit.Operators exposing (..)
import Tuple2
import X.Function exposing (..)
import X.Function.Infix exposing (..)
import X.List
import X.Predicate
import X.Record exposing (..)
import X.Return exposing (..)


type alias ModelRecord =
    { path : List String
    , namedFilterModel : NamedFilterModel
    , cursor : EntityListCursor.Model
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
            let
                onSetCursorEntityId pageModel =
                    let
                        entityIdList =
                            createEntityIdList appModel pageModel

                        cursor =
                            EntityListCursor.create entityIdList
                                (Just entityId)
                                (getFilter pageModel)
                    in
                    set cursorFL cursor pageModel
            in
            map onSetCursorEntityId

        MoveFocusBy offset ->
            returnWithMaybe2 (get cursorFL)
                (EntityListCursor.findEntityIdByOffsetIndex offset
                    >>? (SetCursorEntityId >> update config appModel)
                )


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
            X.Predicate.all [ Document.isNotDeleted, TodoDoc.isDone ]

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
