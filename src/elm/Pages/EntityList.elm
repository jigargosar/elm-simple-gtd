module Pages.EntityList exposing (..)

import AppColors
import Color exposing (Color)
import Data.EntityTree
import Data.TodoDoc
import Document exposing (..)
import Entity exposing (..)
import EntityListCursor
import GroupDoc exposing (..)
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


type NamedFilter
    = NF_FL_Done
    | NF_FL_Recent
    | NF_FL_Bin
    | NF_GB_ActiveContexts
    | NF_GB_ActiveProjects
    | NF_WithContextId_GB_Projects DocId
    | NF_WithProjectId_GB_Contexts DocId


type FlatFilterName
    = Done
    | Recent
    | Bin


type Filter
    = ContextView DocId
    | ProjectView DocId
    | FlatListFilter FlatFilterName
    | GroupByFilter GroupDocType


type alias Model =
    { path : List String
    , title : String
    , color : Color
    , filter : Filter
    }


defaultModel =
    { path = [ "contexts" ]
    , title = "Contexts"
    , color = AppColors.contextsColor
    , filter = GroupByFilter ContextGroupDocType
    }


contextModel id =
    { path = "context" :: id :: []
    , title = "Context"
    , color = AppColors.defaultContextColor
    , filter = ContextView id
    }


projectModel id =
    { path = "project" :: id :: []
    , title = "Project"
    , color = AppColors.defaultProjectColor
    , filter = ProjectView id
    }


initFromPath : List String -> Maybe Model
initFromPath path =
    case path of
        "done" :: [] ->
            Just
                { path = [ "done" ]
                , title = "Done"
                , color = AppColors.sgtdBlue
                , filter = FlatListFilter Done
                }

        "bin" :: [] ->
            Just
                { path = [ "bin" ]
                , title = "Bin"
                , color = AppColors.sgtdBlue
                , filter = FlatListFilter Bin
                }

        "recent" :: [] ->
            Just
                { path = [ "recent" ]
                , title = "Recent"
                , color = AppColors.sgtdBlue
                , filter = FlatListFilter Recent
                }

        "contexts" :: [] ->
            Just defaultModel

        "projects" :: [] ->
            Just
                { path = [ "projects" ]
                , title = "Projects"
                , color = AppColors.projectsColor
                , filter = GroupByFilter ProjectGroupDocType
                }

        "context" :: id :: [] ->
            contextModel id |> Just

        "project" :: id :: [] ->
            projectModel id |> Just

        _ ->
            Nothing


type Msg
    = ArrowUp
    | ArrowDown
    | SetFocusableEntityId EntityId
    | ToggleSelection EntityId


entityListCursorFL =
    fieldLens .entityListCursor (\s b -> { b | entityListCursor = s })


maybeEntityIdAtCursorFL =
    let
        maybeEntityIdAtCursorFL =
            fieldLens .maybeEntityIdAtCursor (\s b -> { b | maybeEntityIdAtCursor = s })
    in
    composeInnerOuterFieldLens maybeEntityIdAtCursorFL entityListCursorFL



--updateDefault config msg =
--    update config msg defaultModel


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


updateEntityListCursorWithMaybeEntityId config maybeEntityIdAtCursor model appModel =
    let
        entityIdList =
            createEntityList model appModel
                .|> Entity.toEntityId

        --        _ =
        --            maybeEntityIdAtCursor
        --                |> Debug.log "maybeEntityIdAtCursor"
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


createEntityTree model appModel =
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
    case model.filter of
        ContextView id ->
            Models.GroupDocStore.findContextById id appModel
                ?= GroupDoc.nullContext
                |> Data.EntityTree.initContextRoot
                    getActiveTodoListForContextHelp
                    findProjectByIdHelp

        ProjectView id ->
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

        FlatListFilter namedFilter ->
            let
                pred =
                    namedFilterToPredicate namedFilter
            in
            Data.EntityTree.initTodoForest
                model.title
                (filterTodosAndSortByLatestModified pred appModel)


namedFilterToPredicate filterType =
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
