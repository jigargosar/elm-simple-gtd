module Pages.EntityList exposing (..)

import Color exposing (Color)
import Colors
import Data.EntityList exposing (..)
import Data.EntityTree
import Data.TodoDoc
import Document exposing (..)
import Entity exposing (..)
import EntityListCursor
import GroupDoc exposing (..)
import List.Extra
import Maybe.Extra as Maybe
import Models.GroupDocStore exposing (..)
import Models.Selection
import Models.Stores
import Store
import Toolkit.Helpers exposing (..)
import Toolkit.Operators exposing (..)
import Tuple2
import X.Function exposing (..)
import X.List
import X.Predicate
import X.Record exposing (..)
import X.Return exposing (..)
import X.Set exposing (toggleSetMember)


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
    PageModel activeContextsNamedFilter.pathPrefix activeContextsNamedFilter


initFromPath : List String -> Maybe PageModel
initFromPath path =
    Data.EntityList.getMaybeNamedFilterModelFromPath path
        ?|> PageModel path


getPath (PageModel path _) =
    path


getTitleColourTuple (PageModel _ namedFilterModel) =
    namedFilterModel |> (\model -> ( model.displayName, model.headerColor ))


getTitle (PageModel path namedFilterModel) =
    namedFilterModel.displayName


getFilter (PageModel path namedFilterModel) =
    case namedFilterModel.namedFilter of
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
    = ArrowUp
    | ArrowDown
    | SetFocusableEntityId EntityId
    | ToggleSelection EntityId


update config msg model =
    case msg of
        SetFocusableEntityId entityId ->
            map (updateEntityListCursorWithMaybeEntityId config (entityId |> Just) model)

        ArrowUp ->
            moveFocusBy config -1 model

        ArrowDown ->
            moveFocusBy config 1 model

        ToggleSelection entityId ->
            map
                (Models.Selection.updateSelectedEntityIdSet
                    (toggleSetMember (getDocIdFromEntityId entityId))
                )


entityListCursorFL =
    fieldLens .entityListCursor (\s b -> { b | entityListCursor = s })


maybeEntityIdAtCursorFL =
    let
        maybeEntityIdAtCursorFL =
            fieldLens .maybeEntityIdAtCursor (\s b -> { b | maybeEntityIdAtCursor = s })
    in
    composeInnerOuterFieldLens maybeEntityIdAtCursorFL entityListCursorFL


updateEntityListCursorWithMaybeEntityId config maybeEntityIdAtCursor model appModel =
    let
        entityIdList =
            createEntityList model appModel
                .|> Entity.toEntityId

        cursor =
            { entityIdList = entityIdList
            , maybeEntityIdAtCursor = maybeEntityIdAtCursor
            }
    in
    setIn appModel entityListCursorFL cursor


moveFocusBy config offset model =
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
                        model
                        appModel

                entityIdList =
                    createEntityList model appModel
                        .|> Entity.toEntityId
            in
            findEntityIdByOffsetIn offset
                entityIdList
                maybeEntityIdAtCursorOld
                ?|> (SetFocusableEntityId >> update config # model)
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

        maybeNameFilterModel =
            getMaybeNamedFilterModelFromType
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


createEntityList model appModel =
    createEntityTree model appModel |> Data.EntityTree.flatten


computeMaybeNewEntityIdAtCursor model appModel =
    let
        newEntityIdList =
            createEntityList model appModel
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
    in
    getAndMaybeApply maybeEntityIdAtCursorFL computeNewEntityIdAtCursor appModel
        ?= List.head newEntityIdList
