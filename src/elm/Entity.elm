module Entity exposing (..)

import Document exposing (getDocId)
import Entity.Types exposing (..)
import X.Function exposing (..)
import X.Function.Infix exposing (..)


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
