module Stores exposing (..)

import Data.DeviceId exposing (DeviceId)
import Data.TodoDoc exposing (TodoStore)
import GroupDoc exposing (ContextStore, ProjectStore)
import Json.Decode as D exposing (Decoder)
import Json.Decode.Pipeline as D
import Json.Encode as E
import List.Extra as List
import Maybe.Extra as Maybe
import Random.Pcg
import Time exposing (Time)
import Toolkit.Helpers exposing (..)
import Toolkit.Operators exposing (..)
import X.Function exposing (..)
import X.Function.Infix exposing (..)
import X.Random


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
                (Data.TodoDoc.storeGenerator deviceId encodedLists.todo)
                (GroupDoc.projectStoreGenerator deviceId encodedLists.project)
                (GroupDoc.contextStoreGenerator deviceId encodedLists.context)

        ( ( todoStore, projectStore, contextStore ), seed ) =
            Random.Pcg.step storeGenerator (X.Random.seedFromTime now)
    in
    { todoStore = todoStore
    , projectStore = projectStore
    , contextStore = contextStore
    }
