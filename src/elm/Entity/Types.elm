module Entity.Types exposing (..)

import Document.Types exposing (DocId)
import GroupDoc.Types exposing (GroupDoc)
import Todo.Types exposing (TodoDoc)
import X.Keyboard


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


type EntityMsg
    = EM_Update EntityId EntityUpdateAction
    | EM_EntityListKeyDown (List Entity) X.Keyboard.KeyboardEvent


type EntityUpdateAction
    = EUA_OnFocusIn
    | EUA_ToggleSelection
    | EUA_OnGotoEntity


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
