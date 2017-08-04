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
    , entityListPageModel : PageModel
    }


type alias HasEntityListCursor a =
    { a | entityListCursor : EntityListCursor }


entityListCursorInitialValue : EntityListCursor
entityListCursorInitialValue =
    { entityIdList = []
    , maybeEntityIdAtCursor = Nothing
    , entityListPageModel = defaultPageModel
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


type PageModel
    = PageModel (List String) NamedFilterModel


defaultPageModel =
    PageModel defaultNamedFilterModel.pathPrefix defaultNamedFilterModel


initFromPath : List String -> Maybe PageModel
initFromPath path =
    getMaybeNamedFilterModelFromPath path
        ?|> PageModel path


getFullPath (PageModel path _) =
    path


getTitleColourTuple (PageModel _ namedFilterModel) =
    namedFilterModel |> (\model -> ( model.displayName, model.headerColor ))


getTitle (PageModel path namedFilterModel) =
    namedFilterModel.displayName


getFilter (PageModel path namedFilterModel) =
    case namedFilterModel.namedFilterType of
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
            ContextIdFilter (List.Extra.last path ?= "")

        NF_WithProjectId_GB_Contexts ->
            ProjectIdFilter (List.Extra.last path ?= "")


getNamedFilterModel (PageModel path namedFilterModel) =
    namedFilterModel


type Msg
    = MoveFocusBy Int
    | SetCursorEntityId EntityId


update config msg pageModel =
    case msg of
        SetCursorEntityId entityId ->
            -- note: this is automatically called by focusIn event of list item.
            map (updateEntityListCursorWithMaybeEntityId config (entityId |> Just) pageModel)

        MoveFocusBy offset ->
            moveFocusBy config offset pageModel


entityListCursorFL =
    fieldLens .entityListCursor (\s b -> { b | entityListCursor = s })


maybeEntityIdAtCursorFL =
    let
        maybeEntityIdAtCursorFL =
            fieldLens .maybeEntityIdAtCursor (\s b -> { b | maybeEntityIdAtCursor = s })
    in
    composeInnerOuterFieldLens maybeEntityIdAtCursorFL entityListCursorFL


entityListCursorPageModelFL =
    let
        entityListPageModelFL =
            fieldLens .entityListPageModel (\s b -> { b | entityListPageModel = s })
    in
    composeInnerOuterFieldLens entityListPageModelFL entityListCursorFL


updateEntityListCursorWithMaybeEntityId config maybeEntityIdAtCursor pageModel appModel =
    let
        entityIdList =
            createEntityList pageModel appModel
                .|> Entity.toEntityId

        cursor =
            { entityIdList = entityIdList
            , maybeEntityIdAtCursor = maybeEntityIdAtCursor
            , entityListPageModel = pageModel
            }
    in
    setIn appModel entityListCursorFL cursor


moveFocusBy config offset pageModel =
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
        (\appModel ->
            let
                maybeEntityIdAtCursorOld =
                    computeMaybeNewEntityIdAtCursor
                        pageModel
                        appModel

                entityIdList =
                    createEntityList pageModel appModel
                        .|> Entity.toEntityId
            in
            findEntityIdByOffsetIn offset
                entityIdList
                maybeEntityIdAtCursorOld
                ?|> (SetCursorEntityId >> update config # pageModel)
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


computeMaybeNewEntityIdAtCursor pageModel appModel =
    let
        newEntityIdList =
            createEntityList pageModel appModel
                .|> Entity.toEntityId

        computeMaybeFEI index =
            X.List.clampAndGetAtIndex index newEntityIdList

        computeNewEntityIdAtCursor entityIdAtCursor =
            ( appModel.entityListCursor.entityIdList, newEntityIdList )
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
            if get entityListCursorPageModelFL appModel == pageModel then
                getAndMaybeApply maybeEntityIdAtCursorFL computeNewEntityIdAtCursor appModel
                    |> Maybe.join
            else
                get maybeEntityIdAtCursorFL appModel
    in
    maybeCompute
        |> Maybe.orElseLazy (\_ -> List.head newEntityIdList)
