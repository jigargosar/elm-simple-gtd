module Entity.Types exposing (..)

import Todo.Types exposing (TodoDoc)
import Types.Document exposing (..)
import Types.GroupDoc exposing (..)


type GroupEntityType
    = ProjectEntity GroupDoc
    | ContextEntity GroupDoc


type Entity
    = GroupEntity GroupEntityType
    | TodoEntity TodoDoc


type EntityUpdateAction
    = EUA_ToggleSelection
    | EUA_OnGotoEntity
    | EUA_BringEntityIdInView


type EntityMsg
    = EM_SetFocusInEntityWithEntityId EntityId
    | EM_Update EntityId EntityUpdateAction
    | EM_EntityListFocusPrev
    | EM_EntityListFocusNext
    | EM_UpdateEntityListCursor


createContextEntity =
    ContextEntity >> GroupEntity


createProjectEntity =
    ProjectEntity >> GroupEntity


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
