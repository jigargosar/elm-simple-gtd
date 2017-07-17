module Stores exposing (..)

import Document
import Entity
import Entity.Tree
import Entity.Types exposing (..)
import EntityId
import Model.EntityTree
import Model.GroupDocStore exposing (..)
import Model.TodoStore exposing (..)
import Model.ViewType
import Return exposing (andThen)
import Store
import Todo
import Todo.Types exposing (TodoAction(TA_AutoSnooze), TodoDoc, TodoStore)
import Toolkit.Operators exposing (..)
import X.Function.Infix exposing (..)
import List.Extra as List
import Maybe.Extra as Maybe
import X.Record exposing (maybeOverT2, maybeSetIn, overT2, set, setIn)
import Set
import Tuple2
import X.List


--insertTodo : (DeviceId -> DocId -> TodoDoc) -> AppModel -> ( TodoDoc, AppModel )


insertTodo constructWithId =
    X.Record.overT2 todoStore (Store.insert (constructWithId))



--upsertEncodedDocOnPouchDBChange : String -> E.Value -> AppModel -> Maybe ( Entity, AppModel )


upsertEncodedDocOnPouchDBChange dbName encodedEntity =
    case dbName of
        "todo-db" ->
            maybeOverT2 todoStore (Store.upsertOnPouchDBChange encodedEntity)
                >>? Tuple.mapFirst createTodoEntity

        "project-db" ->
            maybeOverT2 projectStore (Store.upsertOnPouchDBChange encodedEntity)
                >>? Tuple.mapFirst createProjectEntity

        "context-db" ->
            maybeOverT2 contextStore (Store.upsertOnPouchDBChange encodedEntity)
                >>? Tuple.mapFirst createContextEntity

        _ ->
            (\_ -> Nothing)


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
                        (createEntityListForCurrentView model)
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
                (createEntityListForCurrentView >> (getMaybeFocusInEntityIndex # oldModel))
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
            (createEntityListForCurrentView >> (getMaybeFocusInEntityIndex # oldModel))
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
                (createEntityListForCurrentView model)
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


createEntityListForCurrentView model =
    Model.ViewType.maybeGetEntityListViewType model
        ?|> (Model.EntityTree.createEntityTreeForViewType # model >> Entity.Tree.flatten)
        ?= []



--updateTodo : TodoAction -> DocId -> ModelReturnF


updateTodo action todoId =
    findAndUpdateAllTodos (Document.hasId todoId) action



--updateAllTodos : TodoAction -> Document.IdSet -> ModelReturnF


updateAllTodos action idSet model =
    findAndUpdateAllTodos (Document.getId >> Set.member # idSet) action model


updateTodoAndMaybeAlsoSelected action todoId model =
    let
        idSet =
            if model.selectedEntityIdSet |> Set.member todoId then
                model.selectedEntityIdSet
            else
                Set.singleton todoId
    in
        model |> updateAllTodos action idSet


findTodoWithOverDueReminder model =
    model.todoStore |> Store.findBy (Todo.isReminderOverdue model.now)



--findAndSnoozeOverDueTodo : AppModel -> Maybe ( ( TodoDoc, AppModel ), Cmd AppMsg )


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



--upsertEncodedDocOnFirebaseDatabaseChange : String -> E.Value -> AppModel -> Cmd msg


upsertEncodedDocOnFirebaseDatabaseChange dbName encodedEntity =
    case dbName of
        "todo-db" ->
            .todoStore >> (Store.upsertInPouchDbOnFirebaseChange encodedEntity)

        "project-db" ->
            .projectStore >> (Store.upsertInPouchDbOnFirebaseChange encodedEntity)

        "context-db" ->
            .contextStore >> (Store.upsertInPouchDbOnFirebaseChange encodedEntity)

        _ ->
            (\_ -> Cmd.none)



{- setFocusInEntityWithTodoId : DocId -> AppModelF -}


setFocusInEntityWithTodoId =
    EntityId.fromTodoDocId >> setFocusInEntityWithEntityId


setFocusInEntity entity =
    set focusInEntity entity


setFocusInEntityWithEntityId entityId model =
    findEntityByEntityId entityId model
        ?|> setIn model focusInEntity
        ?= model


findEntityByEntityId entityId =
    case entityId of
        ContextId id ->
            findContextById id >>? createContextEntity

        ProjectId id ->
            findProjectById id >>? createProjectEntity

        TodoId id ->
            findTodoById id >>? createTodoEntity
