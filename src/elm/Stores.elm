module Stores exposing (..)

import Data.DeviceId exposing (DeviceId)
import Data.TodoDoc as TodoDoc exposing (TodoStore)
import Document exposing (DocId)
import Entity exposing (Entity(..))
import GroupDoc exposing (ContextStore, ProjectStore)
import Json.Encode as E
import Models.GroupDocStore exposing (contextStore, projectStore)
import Models.Selection
import Models.TodoDocStore as TodoDocStore
import Ports
import Random.Pcg
import Set exposing (Set)
import Store
import Time exposing (Time)
import Toolkit.Helpers exposing (..)
import Toolkit.Operators exposing (..)
import X.Function.Infix exposing (..)
import X.Random
import X.Record exposing (..)
import X.Return exposing (..)
import XUpdate as U


type alias Model =
    { todoStore : TodoStore
    , projectStore : ProjectStore
    , contextStore : ContextStore
    }


type alias EncodedLists =
    { todo : List E.Value
    , project : List E.Value
    , context : List E.Value
    }


fromStores todoStore contextStore projectStore =
    Model todoStore projectStore contextStore


initialValue : Time -> DeviceId -> EncodedLists -> ( Model, Random.Pcg.Seed )
initialValue now deviceId encodedLists =
    let
        storeGenerator =
            Random.Pcg.map3 (,,)
                (TodoDoc.storeGenerator deviceId encodedLists.todo)
                (GroupDoc.projectStoreGenerator deviceId encodedLists.project)
                (GroupDoc.contextStoreGenerator deviceId encodedLists.context)

        ( ( todoStore, projectStore, contextStore ), seed ) =
            Random.Pcg.step storeGenerator (X.Random.seedFromTime now)
    in
    ( { todoStore = todoStore
      , projectStore = projectStore
      , contextStore = contextStore
      }
    , seed
    )


type Msg
    = UpdateTodo DocId TodoDoc.TodoAction
    | UpdateAllTodo (Set DocId) TodoDoc.TodoAction
    | OnPouchDBChange String E.Value
    | OnFirebaseDatabaseChange String E.Value


subscriptions =
    Sub.batch
        [ Ports.pouchDBChanges (uncurry OnPouchDBChange)
        , Ports.onFirebaseDatabaseChange (uncurry OnFirebaseDatabaseChange)
        ]


type alias Config msg a =
    { a
        | recomputeEntityListCursorAfterChangesReceivedFromPouchDBMsg : msg
    }


update : Config msg a -> Msg -> Model -> U.Return Model Msg msg
update config msg model =
    let
        defRet =
            U.pure model
    in
    case msg of
        OnPouchDBChange dbName encodedDoc ->
            upsertEncodedDocOnPouchDBChange dbName encodedDoc model
                ?|> (Tuple.second >> U.pure)
                ?= defRet
                |> U.addMsg config.recomputeEntityListCursorAfterChangesReceivedFromPouchDBMsg

        OnFirebaseDatabaseChange dbName encodedDoc ->
            defRet
                |> U.addEffect (upsertEncodedDocOnFirebaseDatabaseChange dbName encodedDoc)

        _ ->
            defRet


upsertEncodedDocOnPouchDBChange dbName encodedEntity =
    case dbName of
        "todo-db" ->
            maybeOverT2 TodoDocStore.todoStore (Store.upsertInMemoryOnPouchDBChange encodedEntity)
                >>? Tuple.mapFirst Entity.createTodoEntity

        "project-db" ->
            maybeOverT2 projectStore (Store.upsertInMemoryOnPouchDBChange encodedEntity)
                >>? Tuple.mapFirst Entity.createProjectEntity

        "context-db" ->
            maybeOverT2 contextStore (Store.upsertInMemoryOnPouchDBChange encodedEntity)
                >>? Tuple.mapFirst Entity.createContextEntity

        _ ->
            \_ -> Nothing


upsertEncodedDocOnFirebaseDatabaseChange dbName encodedEntity =
    case dbName of
        "todo-db" ->
            .todoStore >> Store.getUpsertInPouchDbOnFirebaseChangeCmd encodedEntity

        "project-db" ->
            .projectStore >> Store.getUpsertInPouchDbOnFirebaseChangeCmd encodedEntity

        "context-db" ->
            .contextStore >> Store.getUpsertInPouchDbOnFirebaseChangeCmd encodedEntity

        _ ->
            \_ -> Cmd.none
