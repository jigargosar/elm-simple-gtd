module Entity exposing (..)

import Document
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
            TodoId (Document.getId m)

        GroupEntity ge ->
            case ge of
                ProjectEntity m ->
                    ProjectId (Document.getId m)

                ContextEntity m ->
                    ContextId (Document.getId m)


equalById =
    tuple2 >>> mapAllT2 toEntityId >> equalsT2


hasId entityId entity =
    toEntityId entity |> equals entityId
