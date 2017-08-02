module Entity exposing (..)

import Document
import Types.Document exposing (DocId)
import Types.GroupDoc exposing (..)
import Types.Todo exposing (TodoDoc)
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
    = ContextId DocId
    | ProjectId DocId
    | TodoId DocId


getDocIdFromEntityId entityId =
    case entityId of
        ContextId id ->
            id

        ProjectId id ->
            id

        TodoId id ->
            id


createTodoEntityId =
    TodoId


createContextEntityId =
    ContextId


createProjectEntityId =
    ProjectId


toEntityId entity =
    case entity of
        TodoEntity m ->
            TodoId (Document.getId m)

        GroupDocEntityW (GroupDocEntity ContextGroupDocType gd) ->
            ContextId (Document.getId gd)

        GroupDocEntityW (GroupDocEntity ProjectGroupDocType gd) ->
            ProjectId (Document.getId gd)


equalById =
    tuple2 >>> mapAllT2 toEntityId >> equalsT2


hasId entityId entity =
    toEntityId entity |> equals entityId
