module Stores exposing (..)

import Data.DeviceId exposing (DeviceId)
import Data.TodoDoc as TodoDoc exposing (TodoStore)
import Document exposing (DocId)
import GroupDoc exposing (ContextStore, ProjectStore)
import Json.Encode as E
import Random.Pcg
import Set exposing (Set)
import Time exposing (Time)
import X.Random
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


initialValue : Time -> DeviceId -> EncodedLists -> Model
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
    { todoStore = todoStore
    , projectStore = projectStore
    , contextStore = contextStore
    }


type Msg
    = UpdateTodo DocId TodoDoc.TodoAction
    | UpdateAllTodo (Set DocId) TodoDoc.TodoAction
    | Noop


update : Msg -> Model -> U.Return Model Msg msg
update msg model =
    let
        defRet =
            U.pure model
    in
    case msg of
        UpdateTodo id action ->
            defRet

        _ ->
            defRet
