module Entity exposing (..)

import Document.Types exposing (getDocId)
import Entity.Types exposing (Entity(..), EntityId(ContextId, ProjectId, TodoId), EntityListViewType(..), GroupEntityType(..))
import List.Extra as List
import Maybe.Extra as Maybe
import Toolkit.Operators exposing (..)
import X.Function exposing (..)
import X.Function.Infix exposing (..)
import X.List as List


type alias GroupEntity =
    Entity.Types.GroupEntityType


fromContext =
    ContextEntity >> GroupEntity


fromProject =
    ProjectEntity >> GroupEntity


fromTodo =
    TodoEntity


initProjectGroup =
    ProjectEntity


initContextGroup =
    ContextEntity


type alias Msg =
    Entity.Types.EntityUpdateAction


toEntityId entity =
    case entity of
        TodoEntity m ->
            TodoId (getDocId m)

        GroupEntity ge ->
            case ge of
                ProjectEntity m ->
                    ProjectId (getDocId m)

                ContextEntity m ->
                    ContextId (getDocId m)


equalById =
    tuple2 >>> mapAllT2 toEntityId >> equalsT2


hasId entityId entity =
    toEntityId entity |> equals entityId


findEntityByOffsetIn offsetIndex entityList fromEntity =
    entityList
        |> List.findIndex (equalById fromEntity)
        ?= 0
        |> add offsetIndex
        |> List.clampIndexIn entityList
        |> List.atIndexIn entityList
        |> Maybe.orElse (List.head entityList)
