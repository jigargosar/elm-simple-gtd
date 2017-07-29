module Entity.Types exposing (..)

import Document exposing (DocId)
import GroupDoc.Types exposing (GroupDoc)
import Todo.Types exposing (TodoDoc)


type GroupEntityType
    = ProjectEntity GroupDoc
    | ContextEntity GroupDoc


type Entity
    = GroupEntity GroupEntityType
    | TodoEntity TodoDoc


type EntityListViewType
    = ContextsView
    | ContextView DocId
    | ProjectsView
    | ProjectView DocId
    | BinView
    | DoneView
    | RecentView


defaultViewType =
    ContextsView


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
