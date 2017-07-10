module Stores exposing (..)

import Context
import Document
import Document.Types exposing (DeviceId, DocId, getDocId)
import Entity
import Entity.Tree
import Entity.Types exposing (EntityListViewType, Entity)
import GroupDoc
import GroupDoc.Types exposing (ContextStore, ProjectStore)
import Msg exposing (Msg)
import Project
import Return
import Store
import Todo
import Todo.Types exposing (TodoAction(TA_AutoSnooze), TodoDoc, TodoStore)
import Toolkit.Helpers exposing (maybe2Tuple)
import Toolkit.Operators exposing (..)
import Types exposing (AppModel, ModelF, ModelReturnF)
import ViewType exposing (ViewType(EntityListView))
import X.Function exposing (..)
import X.Function.Infix exposing (..)
import List.Extra as List
import Maybe.Extra as Maybe
import X.Record exposing (maybeOverT2, maybeSetIn, overT2, set)
import Json.Encode as E
import Set
import Tuple2
import X.List
import X.Predicate


contextStore =
    X.Record.field .contextStore (\s b -> { b | contextStore = s })


projectStore =
    X.Record.field .projectStore (\s b -> { b | projectStore = s })


todoStore =
    X.Record.field .todoStore (\s b -> { b | todoStore = s })


focusInEntity =
    X.Record.field .focusInEntity (\s b -> { b | focusInEntity = s })


createContext text model =
    model
        |> overT2 contextStore (Store.insert (Context.init text model.now))
        |> Tuple.second


createProject text model =
    model
        |> overT2 projectStore (Store.insert (Project.init text model.now))
        |> Tuple.second


insertTodo : (DeviceId -> DocId -> TodoDoc) -> AppModel -> ( TodoDoc, AppModel )
insertTodo constructWithId =
    X.Record.overT2 todoStore (Store.insert (constructWithId))


upsertEncodedDocOnPouchDBChange : String -> E.Value -> AppModel -> Maybe ( Entity, AppModel )
upsertEncodedDocOnPouchDBChange dbName encodedEntity =
    case dbName of
        "todo-db" ->
            maybeOverT2 todoStore (Store.upsertOnPouchDBChange encodedEntity)
                >>? Tuple.mapFirst Entity.fromTodo

        "project-db" ->
            maybeOverT2 projectStore (Store.upsertOnPouchDBChange encodedEntity)
                >>? Tuple.mapFirst Entity.fromProject

        "context-db" ->
            maybeOverT2 contextStore (Store.upsertOnPouchDBChange encodedEntity)
                >>? Tuple.mapFirst Entity.fromContext

        _ ->
            (\_ -> Nothing)


updateAllNamedDocsDocs idSet updateFn store model =
    X.Record.overT2 store
        (Store.updateAndPersist
            (getDocId >> Set.member # idSet)
            model.now
            updateFn
        )
        model
        |> Tuple2.swap
        |> Return.map (updateEntityListCursorOnGroupDocChange model)


updateEntityListCursorOnGroupDocChange oldModel newModel =
    let
        updateEntityListCursorFromEntityIndexTuple model indexTuple =
            let
                setFocusInEntityByIndex index entityList model =
                    X.List.clampIndex index entityList
                        |> (List.getAt # entityList)
                        |> Maybe.orElse (List.head entityList)
                        |> maybeSetIn model focusInEntity

                setFocusInIndex index =
                    setFocusInEntityByIndex
                        index
                        (getCurrentViewEntityList model)
            in
                model
                    |> case indexTuple of
                        -- not we want focus to remain on group entity, when edited, since its sort order may change. But if removed from view, we want to focus on next entity.
                        {- ( Just oldIndex, Just newIndex ) ->
                           if oldIndex < newIndex then
                               setFocusInIndex (oldIndex)
                           else if oldIndex > newIndex then
                               setFocusInIndex (oldIndex + 1)
                           else
                               identity
                        -}
                        ( Just oldIndex, Nothing ) ->
                            setFocusInIndex oldIndex

                        _ ->
                            identity
    in
        ( oldModel, newModel )
            |> Tuple2.mapBoth
                (getCurrentViewEntityList >> (getMaybeFocusInEntityIndex # oldModel))
            |> updateEntityListCursorFromEntityIndexTuple newModel


findAndUpdateAllTodos findFn action model =
    let
        updateFn =
            Todo.update action
    in
        X.Record.overT2 todoStore (Store.updateAndPersist findFn model.now updateFn) model
            |> Tuple2.swap
            |> Return.map (updateEntityListCursor model)


updateEntityListCursor oldModel newModel =
    ( oldModel, newModel )
        |> Tuple2.mapBoth
            (getCurrentViewEntityList >> (getMaybeFocusInEntityIndex # oldModel))
        |> updateEntityListCursorFromEntityIndexTuple newModel


getMaybeFocusInEntityIndex entityList model =
    entityList
        |> List.findIndex (Entity.equalById model.focusInEntity)


updateEntityListCursorFromEntityIndexTuple model indexTuple =
    let
        setFocusInEntityByIndex index entityList model =
            X.List.clampIndex index entityList
                |> (List.getAt # entityList)
                |> Maybe.orElse (List.head entityList)
                |> maybeSetIn model focusInEntity

        setFocusInIndex index =
            setFocusInEntityByIndex
                index
                (getCurrentViewEntityList model)
    in
        model
            |> case indexTuple of
                ( Just oldIndex, Just newIndex ) ->
                    if oldIndex < newIndex then
                        setFocusInIndex (oldIndex)
                    else if oldIndex > newIndex then
                        setFocusInIndex (oldIndex + 1)
                    else
                        identity

                ( Just oldIndex, Nothing ) ->
                    setFocusInIndex oldIndex

                _ ->
                    identity


getCurrentViewEntityList model =
    --todo: can use maybeGetCurrentEntityListViewType
    case model.mainViewType of
        EntityListView viewType ->
            createGrouping viewType model |> Entity.Tree.flatten

        _ ->
            []


filterTodosAndSortBy pred sortBy model =
    Store.filterDocs pred model.todoStore
        |> List.sortBy sortBy


filterTodosAndSortByLatestCreated pred =
    filterTodosAndSortBy pred (Todo.getCreatedAt >> negate)


filterTodosAndSortByLatestModified pred =
    filterTodosAndSortBy pred (Todo.getModifiedAt >> negate)


filterContexts pred model =
    Store.filterDocs pred model.contextStore
        |> List.append (Context.filterNull pred)
        |> Context.sort


filterProjects pred model =
    Store.filterDocs pred model.projectStore
        |> List.append (Project.filterNull pred)
        |> Project.sort


findTodoById : DocId -> AppModel -> Maybe TodoDoc
findTodoById id =
    .todoStore >> Store.findById id


findProjectById : DocId -> AppModel -> Maybe Project.Model
findProjectById id =
    .projectStore
        >> Store.findById id
        >> Maybe.orElseLazy (\_ -> ([ Project.null ] |> List.find (Document.hasId id)))


findProjectByIdIn =
    flip findProjectById


findContextById : DocId -> AppModel -> Maybe Context.Model
findContextById id =
    .contextStore
        >> Store.findById id
        >> Maybe.orElseLazy (\_ -> ([ Context.null ] |> List.find (Document.hasId id)))


findContextByIdIn =
    flip findContextById


isTodoContextActive model =
    Todo.getContextId
        >> findContextByIdIn model
        >>? GroupDoc.isActive
        >>?= True


isTodoProjectActive model =
    Todo.getProjectId
        >> findProjectByIdIn model
        >>? GroupDoc.isActive
        >>?= True


getActiveTodoListHavingActiveContext model =
    model.todoStore |> Store.filterDocs (allPass [ Todo.isActive, isTodoContextActive model ])


getActiveTodoListHavingActiveProject model =
    model.todoStore |> Store.filterDocs (allPass [ Todo.isActive, isTodoProjectActive model ])


getActiveTodoListForContext context model =
    filterTodosAndSortByLatestCreated
        (X.Predicate.all
            [ Todo.isActive
            , Todo.contextFilter context
            , isTodoProjectActive model
            ]
        )
        model


getActiveTodoListForProject project model =
    filterTodosAndSortByLatestCreated
        (X.Predicate.all
            [ Todo.isActive
            , Todo.hasProject project
            , isTodoContextActive model
            ]
        )
        model


getActiveProjects =
    filterProjects GroupDoc.isActive


getActiveContexts =
    filterContexts GroupDoc.isActive


createGrouping : EntityListViewType -> AppModel -> Entity.Tree.Tree
createGrouping viewType model =
    let
        getActiveTodoListForContextHelp =
            getActiveTodoListForContext # model

        getActiveTodoListForProjectHelp =
            getActiveTodoListForProject # model

        findProjectByIdHelp =
            findProjectById # model

        findContextByIdHelp =
            findContextById # model
    in
        case viewType of
            Entity.Types.ContextsView ->
                getActiveContexts model
                    |> Entity.Tree.initContextForest
                        getActiveTodoListForContextHelp

            Entity.Types.ProjectsView ->
                getActiveProjects model
                    |> Entity.Tree.initProjectForest
                        getActiveTodoListForProjectHelp

            Entity.Types.ContextView id ->
                findContextById id model
                    ?= Context.null
                    |> Entity.Tree.initContextRoot
                        getActiveTodoListForContextHelp
                        findProjectByIdHelp

            Entity.Types.ProjectView id ->
                findProjectById id model
                    ?= Project.null
                    |> Entity.Tree.initProjectRoot
                        getActiveTodoListForProjectHelp
                        findContextByIdHelp

            Entity.Types.BinView ->
                Entity.Tree.initTodoForest
                    "Bin"
                    (filterTodosAndSortByLatestModified Document.isDeleted model)

            Entity.Types.DoneView ->
                Entity.Tree.initTodoForest
                    "Done"
                    (filterTodosAndSortByLatestModified
                        (X.Predicate.all [ Document.isNotDeleted, Todo.isDone ])
                        model
                    )

            Entity.Types.RecentView ->
                Entity.Tree.initTodoForest
                    "Recent"
                    (filterTodosAndSortByLatestModified X.Predicate.always model)


updateContext id updateFn =
    updateAllNamedDocsDocs (Set.singleton id) updateFn contextStore


updateProject id updateFn =
    updateAllNamedDocsDocs (Set.singleton id) updateFn projectStore


updateTodo : TodoAction -> DocId -> ModelReturnF
updateTodo action todoId =
    findAndUpdateAllTodos (Document.hasId todoId) action


updateAllTodos : TodoAction -> Document.IdSet -> ModelReturnF
updateAllTodos action idSet model =
    findAndUpdateAllTodos (Document.getId >> Set.member # idSet) action model


createTodo text model =
    model
        |> insertTodo (Todo.init model.now text)
        |> Tuple.second


updateTodoAndMaybeAlsoSelected action todoId model =
    let
        idSet =
            if model.selectedEntityIdSet |> Set.member todoId then
                model.selectedEntityIdSet
            else
                Set.singleton todoId
    in
        model |> updateAllTodos action idSet


getActiveTodoListWithReminderTime model =
    model.todoStore |> Store.filterDocs (Todo.isReminderOverdue model.now)


findTodoWithOverDueReminder model =
    model.todoStore |> Store.findBy (Todo.isReminderOverdue model.now)


findAndSnoozeOverDueTodo : AppModel -> Maybe ( ( TodoDoc, AppModel ), Cmd Msg )
findAndSnoozeOverDueTodo model =
    let
        snooze todoId =
            updateTodo (TA_AutoSnooze model.now) todoId model
                |> (\( model, cmd ) ->
                        findTodoById todoId model ?|> (\todo -> ( ( todo, model ), cmd ))
                   )
    in
        Store.findBy (Todo.isReminderOverdue model.now) model.todoStore
            ?+> (Document.getId >> snooze)


upsertEncodedDocOnFirebaseChange : String -> E.Value -> AppModel -> Cmd msg
upsertEncodedDocOnFirebaseChange dbName encodedEntity =
    case dbName of
        "todo-db" ->
            .todoStore >> (Store.upsertInPouchDbOnFirebaseChange encodedEntity)

        "project-db" ->
            .projectStore >> (Store.upsertInPouchDbOnFirebaseChange encodedEntity)

        "context-db" ->
            .contextStore >> (Store.upsertInPouchDbOnFirebaseChange encodedEntity)

        _ ->
            (\_ -> Cmd.none)


setProjectStore : ProjectStore -> ModelF
setProjectStore projectStore model =
    { model | projectStore = projectStore }


setContextStore : ContextStore -> ModelF
setContextStore contextStore model =
    { model | contextStore = contextStore }


setFocusInEntityFromTodoId : DocId -> ModelF
setFocusInEntityFromTodoId todoId model =
    maybe2Tuple ( findTodoById todoId model ?|> Entity.Types.TodoEntity, Just model )
        ?|> uncurry setFocusInEntity
        ?= model


setFocusInEntity entity =
    set focusInEntity entity