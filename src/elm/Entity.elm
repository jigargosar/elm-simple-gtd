module Entity exposing (..)

import Document
import Document.Types exposing (getDocId)
import Entity.Types exposing (Entity(..), EntityId(ContextId, ProjectId, TodoId), EntityListViewType(..), GroupEntityType(..))
import X.List as List
import Toolkit.Operators exposing (..)
import X.Function exposing (..)
import List.Extra as List
import Maybe.Extra as Maybe
import Tuple2


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
    Entity.Types.EntityUpdateMsg


getDocId entity =
    case entity of
        TodoEntity model ->
            Document.getId model

        GroupEntity group ->
            case group of
                ProjectEntity model ->
                    Document.getId model

                ContextEntity model ->
                    Document.getId model


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


equalById e1 e2 =
    ( e1, e2 )
        |> Tuple2.mapBoth toEntityId
        |> uncurry equals


findEntityByOffsetIn offsetIndex entityList fromEntity =
    entityList
        |> List.findIndex (equalById fromEntity)
        ?= 0
        |> add offsetIndex
        |> List.clampIndexIn entityList
        |> List.atIndexIn entityList
        |> Maybe.orElse (List.head entityList)
