module Context exposing (..)

import GroupDoc
import Json.Encode as E
import Random.Pcg as Random
import Types.Document exposing (..)
import Types.GroupDoc exposing (..)
import X.Function exposing (..)


nullContext : GroupDoc
nullContext =
    GroupDoc.constructor nullContextId "" 0 0 False "" "Inbox" False


nullContextId =
    ""


filterNullContext pred =
    [ nullContext ] |> List.filter pred


sortContexts =
    GroupDoc.sort isNullContext


isNullContext =
    equals nullContext


contextStoreGenerator : DeviceId -> List E.Value -> Random.Generator ContextStore
contextStoreGenerator =
    GroupDoc.storeGenerator "context-db"
