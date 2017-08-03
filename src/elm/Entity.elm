module Entity exposing (..)

import Data.TodoDoc exposing (TodoDoc)
import Document exposing (..)
import GroupDoc exposing (..)
import X.Function exposing (..)
import X.Function.Infix exposing (..)


type GroupDocEntity
    = GroupDocEntity GroupDocType GroupDoc


type Entity
    = GroupDocEntityW GroupDocEntity
    | TodoEntity TodoDoc


initProjectGroup =
    GroupDocEntity ProjectGroupDocType


initContextGroup =
    GroupDocEntity ContextGroupDocType


createContextEntity =
    initContextGroup >> GroupDocEntityW


createProjectEntity =
    initProjectGroup >> GroupDocEntityW


createTodoEntity =
    TodoEntity


type EntityId
    = ContextEntityId DocId
    | ProjectEntityId DocId
    | TodoEntityId DocId


getDocIdFromEntityId entityId =
    case entityId of
        ContextEntityId id ->
            id

        ProjectEntityId id ->
            id

        TodoEntityId id ->
            id


createTodoEntityId =
    TodoEntityId


createContextEntityId =
    ContextEntityId


createProjectEntityId =
    ProjectEntityId


toEntityId entity =
    case entity of
        TodoEntity m ->
            TodoEntityId (Document.getId m)

        GroupDocEntityW (GroupDocEntity ContextGroupDocType gd) ->
            ContextEntityId (Document.getId gd)

        GroupDocEntityW (GroupDocEntity ProjectGroupDocType gd) ->
            ProjectEntityId (Document.getId gd)


equalById =
    tuple2 >>> mapAllT2 toEntityId >> equalsT2


hasId entityId entity =
    toEntityId entity |> equals entityId
