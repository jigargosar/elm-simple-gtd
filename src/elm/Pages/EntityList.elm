module Pages.EntityList exposing (..)

import AppColors
import Color exposing (Color)
import Context
import Data.EntityTree
import Document
import Entity
import Entity.Types exposing (EntityId(TodoId))
import EntityId
import EntityListCursor
import GroupDoc.View
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Keyed
import List.Extra as List
import Maybe.Extra as Maybe
import Models.EntityTree
import Models.GroupDocStore
import Models.Stores
import Project
import RouteUrl.Builder
import Todo
import Todo.ItemView
import Toolkit.Helpers exposing (..)
import Toolkit.Operators exposing (..)
import Tuple2
import Types.Document exposing (DocId)
import Types.GroupDoc exposing (ContextStore, ProjectStore)
import Types.Todo exposing (TodoStore)
import View.Badge
import X.Function exposing (..)
import X.Function.Infix exposing (..)
import X.List
import X.Predicate
import X.Return exposing (..)


type FilterType
    = Done
    | Recent
    | Bin
    | HavingActiveProjectAndContextId DocId
    | HavingActiveContextAndProjectId DocId


type Filter
    = ContextsView
    | ContextView DocId
    | ProjectsView
    | ProjectView DocId
    | Filter FilterType


type alias Model =
    { path : List String
    , title : String
    , color : Color
    , filter : Filter
    }


initialModel : List String -> Maybe Model
initialModel path =
    case path of
        "done" :: [] ->
            Just
                { path = [ "done" ]
                , title = "Done New"
                , color = AppColors.sgtdBlue
                , filter = Filter Done
                }

        "bin" :: [] ->
            Just
                { path = [ "bin" ]
                , title = "Bin New"
                , color = AppColors.sgtdBlue
                , filter = Filter Bin
                }

        "recent" :: [] ->
            Just
                { path = [ "recent" ]
                , title = "Recent New"
                , color = AppColors.sgtdBlue
                , filter = Filter Recent
                }

        _ ->
            Nothing


type Msg
    = ArrowUp
    | ArrowDown


update config msg =
    case msg of
        ArrowUp ->
            identity

        ArrowDown ->
            identity


moveFocusBy config offset =
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
        (\model ->
            let
                maybeEntityIdAtCursorOld =
                    EntityListCursor.computeMaybeNewEntityIdAtCursorOld
                        config.maybeEntityListPageModel
                        model

                entityIdList =
                    EntityListCursor.createEntityListFormMaybeEntityListPageModelOld config.maybeEntityListPageModel model
                        .|> Entity.toEntityId
            in
            findEntityIdByOffsetIn offset
                entityIdList
                maybeEntityIdAtCursorOld
                ?|> (config.setFocusInEntityWithEntityId >> returnMsgAsCmd)
        )


createEntityTree model appModel =
    let
        getActiveTodoListForContextHelp =
            Models.EntityTree.getActiveTodoListForContext # appModel

        getActiveTodoListForProjectHelp =
            Models.EntityTree.getActiveTodoListForProject # appModel

        findProjectByIdHelp =
            Models.GroupDocStore.findProjectById # appModel

        findContextByIdHelp =
            Models.GroupDocStore.findContextById # appModel
    in
    case model.filter of
        ContextsView ->
            Models.GroupDocStore.getActiveContexts appModel
                |> Data.EntityTree.initContextForest
                    getActiveTodoListForContextHelp

        ProjectsView ->
            Models.GroupDocStore.getActiveProjects appModel
                |> Data.EntityTree.initProjectForest
                    getActiveTodoListForProjectHelp

        ContextView id ->
            Models.GroupDocStore.findContextById id appModel
                ?= Context.null
                |> Data.EntityTree.initContextRoot
                    getActiveTodoListForContextHelp
                    findProjectByIdHelp

        ProjectView id ->
            Models.GroupDocStore.findProjectById id appModel
                ?= Project.null
                |> Data.EntityTree.initProjectRoot
                    getActiveTodoListForProjectHelp
                    findContextByIdHelp

        Filter filterType ->
            Data.EntityTree.initTodoForest
                model.title
                (Models.EntityTree.filterTodosAndSortByLatestModified
                    (filterTypeToPredicate filterType appModel)
                    appModel
                )


filterTypeToPredicate filterType model =
    case filterType of
        Done ->
            X.Predicate.all [ Document.isNotDeleted, Todo.isDone ]

        Recent ->
            X.Predicate.always

        Bin ->
            Document.isDeleted

        HavingActiveProjectAndContextId contextId ->
            X.Predicate.all
                [ Todo.isActive
                , Todo.getContextId >> equals contextId
                , Models.Stores.isTodoProjectActive model
                ]

        HavingActiveContextAndProjectId projectId ->
            X.Predicate.all
                [ Todo.isActive
                , Todo.getProjectId >> equals projectId
                , Models.Stores.isTodoContextActive model
                ]


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
                            ( Just oldIndex, Just newIndex, TodoId _ ) ->
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
    appModel.entityListCursor.maybeEntityIdAtCursor
        ?|> computeNewEntityIdAtCursor
        ?= List.head newEntityIdList
