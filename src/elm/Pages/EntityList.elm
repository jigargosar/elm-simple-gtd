module Pages.EntityList exposing (..)

import AppColors
import Color exposing (Color)
import Context
import Document
import Entity
import Entity.Tree
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


type Filter
    = ContextsView
    | ContextView DocId
    | ProjectsView
    | ProjectView DocId
    | BinView
    | DoneView
    | RecentView


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
                , title = "Done"
                , color = AppColors.sgtdBlue
                , filter = DoneView
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


createEntityTree filter model =
    let
        getActiveTodoListForContextHelp =
            Models.EntityTree.getActiveTodoListForContext # model

        getActiveTodoListForProjectHelp =
            Models.EntityTree.getActiveTodoListForProject # model

        findProjectByIdHelp =
            Models.GroupDocStore.findProjectById # model

        findContextByIdHelp =
            Models.GroupDocStore.findContextById # model
    in
    case filter of
        ContextsView ->
            Models.GroupDocStore.getActiveContexts model
                |> Entity.Tree.initContextForest
                    getActiveTodoListForContextHelp

        ProjectsView ->
            Models.GroupDocStore.getActiveProjects model
                |> Entity.Tree.initProjectForest
                    getActiveTodoListForProjectHelp

        ContextView id ->
            Models.GroupDocStore.findContextById id model
                ?= Context.null
                |> Entity.Tree.initContextRoot
                    getActiveTodoListForContextHelp
                    findProjectByIdHelp

        ProjectView id ->
            Models.GroupDocStore.findProjectById id model
                ?= Project.null
                |> Entity.Tree.initProjectRoot
                    getActiveTodoListForProjectHelp
                    findContextByIdHelp

        BinView ->
            Entity.Tree.initTodoForest
                "Bin"
                (Models.EntityTree.filterTodosAndSortByLatestModified Document.isDeleted model)

        DoneView ->
            Entity.Tree.initTodoForest
                "Done"
                (Models.EntityTree.filterTodosAndSortByLatestModified
                    (X.Predicate.all [ Document.isNotDeleted, Todo.isDone ])
                    model
                )

        RecentView ->
            Entity.Tree.initTodoForest
                "Recent"
                (Models.EntityTree.filterTodosAndSortByLatestModified X.Predicate.always model)


createEntityList filter model =
    createEntityTree filter model |> Entity.Tree.flatten


computeMaybeNewEntityIdAtCursor filter model =
    let
        newEntityIdList =
            createEntityList filter model
                .|> Entity.toEntityId

        computeMaybeFEI index =
            X.List.clampAndGetAtIndex index newEntityIdList

        computeNewEntityIdAtCursor entityIdAtCursor =
            ( model.entityListCursor.entityIdList, newEntityIdList )
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
    model.entityListCursor.maybeEntityIdAtCursor
        ?|> computeNewEntityIdAtCursor
        ?= List.head newEntityIdList
