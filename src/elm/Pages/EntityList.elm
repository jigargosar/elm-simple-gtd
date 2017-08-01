module Pages.EntityList exposing (..)

import AppColors
import Color exposing (Color)
import Context
import Data.EntityTree
import Document
import Entity
import Entity.Types exposing (..)
import Maybe.Extra as Maybe
import Models.EntityTree
import Models.GroupDocStore
import Models.Selection
import Models.Stores
import Project
import Todo
import Toolkit.Operators exposing (..)
import Tuple2
import Types.Document exposing (DocId)
import Types.GroupDoc exposing (..)
import X.Function exposing (..)
import X.List
import X.Predicate
import X.Record exposing (..)
import X.Return exposing (..)
import X.Set exposing (toggleSetMember)


type FilterType
    = Done
    | Recent
    | Bin
    | HavingActiveProjectAndContextId
    | HavingActiveContextAndProjectId


type Filter
    = ContextView DocId
    | ProjectView DocId
    | Filter FilterType
    | GroupBy FilterType GroupDocType


type alias Model =
    { path : List String
    , title : String
    , color : Color
    , filter : Filter
    }


defaultModel =
    { path = [ "contexts" ]
    , title = "Contexts New"
    , color = AppColors.contextsColor
    , filter = GroupBy HavingActiveContextAndProjectId ContextGroupDocType
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

        "contexts" :: [] ->
            Just defaultModel

        "projects" :: [] ->
            Just
                { path = [ "projects" ]
                , title = "Projects New"
                , color = AppColors.projectsColor
                , filter = GroupBy HavingActiveProjectAndContextId ProjectGroupDocType
                }

        "Inbox" :: [] ->
            Just
                { path = [ "Inbox" ]
                , title = "Inbox New"
                , color = AppColors.nullContextColor
                , filter = ContextView ""
                }

        "context" :: id :: [] ->
            contextModel id |> Just

        "project" :: "NotAssigned" :: [] ->
            Just
                { path = path
                , title = "No Project"
                , color = AppColors.defaultProjectColor
                , filter = ProjectView ""
                }

        "project" :: id :: [] ->
            projectModel id |> Just

        _ ->
            Nothing


type Msg
    = ArrowUp
    | ArrowDown
    | SetFocusableEntityId EntityId
    | ToggleSelection EntityId
    | GotoNextViewForFocusableEntityId
    | BringEntityIdInView EntityId


entityListCursor =
    fieldLens .entityListCursor (\s b -> { b | entityListCursor = s })


updateDefault config msg =
    update config msg defaultModel


update config msg model =
    case msg of
        SetFocusableEntityId entityId ->
            map (setEntityAtCursor config (entityId |> Just) model)

        ArrowUp ->
            moveFocusBy config -1 model

        ArrowDown ->
            moveFocusBy config 1 model

        ToggleSelection entityId ->
            map
                (Models.Selection.updateSelectedEntityIdSet
                    (toggleSetMember (getDocIdFromEntityId entityId))
                )

        GotoNextViewForFocusableEntityId ->
            --            let
            --                toNextPageModel entityId appModel =
            --                    case entityId of
            --                        ContextId id ->
            --                            contextModel id
            --
            --                        ProjectId id ->
            --                            projectModel id
            --
            --                        TodoId id ->
            --                            let
            --                                getNextPageModelForTodo todo =
            --                                    let
            --                                        contextView =
            --                                            Todo.getContextId todo |> contextModel
            --
            --                                        projectView =
            --                                            Todo.getProjectId todo |> projectModel
            --                                    in
            --                                    case model.filter of
            --                                        GroupBy _ groupDocType ->
            --                                            case groupDocType of
            --                                                ContextGroupDocType ->
            --                                                    projectView
            --
            --                                                ProjectGroupDocType ->
            --                                                    contextView
            --
            --                                        ProjectView _ ->
            --                                            contextView
            --
            --                                        ContextView _ ->
            --                                            projectView
            --
            --                                        _ ->
            --                                            model
            --                            in
            --                            Models.Todo.findTodoById id appModel
            --                                ?|> getNextPageModelForTodo
            --                                ?= model
            --            in
            --            returnWithMaybe2 identity
            --                (\appModel ->
            --                    let
            --                        maybeNewEntityIdAtCursor =
            --                            computeMaybeNewEntityIdAtCursor model appModel
            --
            --                        --                            appModel.entityListCursor.maybeEntityIdAtCursor
            --                    in
            --                    maybeNewEntityIdAtCursor
            --                        ?|> (\entityId ->
            --                                update config (SetFocusableEntityId entityId) model
            --                                    >> (toNextPageModel entityId appModel
            --                                            |> .path
            --                                            |> config.navigateToPathMsg
            --                                            |> returnMsgAsCmd
            --                                       )
            --                            )
            --                )
            identity

        BringEntityIdInView entityId ->
            --            returnWith (createEntityList model)
            --                (List.find (Entity.hasId entityId)
            --                    >> Maybe.unpack
            --                        (\_ ->
            --                            returnMsgAsCmd (defaultModel.path |> config.navigateToPathMsg)
            --                                >> update config (SetFocusableEntityId entityId) model
            --                        )
            --                        (Entity.toEntityId
            --                            >> SetFocusableEntityId
            --                            >> (update config # model)
            --                        )
            --                )
            identity


setEntityAtCursor config maybeEntityIdAtCursor model appModel =
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
    setIn appModel entityListCursor cursor


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

        GroupBy filterType groupDocType ->
            case groupDocType of
                ContextGroupDocType ->
                    Models.GroupDocStore.getActiveContexts appModel
                        |> Data.EntityTree.initContextForest
                            getActiveTodoListForContextHelp

                ProjectGroupDocType ->
                    Models.GroupDocStore.getActiveProjects appModel
                        |> Data.EntityTree.initProjectForest
                            getActiveTodoListForProjectHelp

        Filter filterType ->
            let
                pred =
                    filterTypeToPredicate filterType appModel
            in
            Data.EntityTree.initTodoForest
                model.title
                (Models.EntityTree.filterTodosAndSortByLatestModified
                    (pred "")
                    appModel
                )


filterTypeToPredicate filterType model =
    case filterType of
        Done ->
            \_ -> X.Predicate.all [ Document.isNotDeleted, Todo.isDone ]

        Recent ->
            \_ -> X.Predicate.always

        Bin ->
            \_ -> Document.isDeleted

        HavingActiveProjectAndContextId ->
            \contextId ->
                X.Predicate.all
                    [ Todo.isActive
                    , Todo.getContextId >> equals contextId
                    , Models.Stores.isTodoProjectActive model
                    ]

        HavingActiveContextAndProjectId ->
            \projectId ->
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
