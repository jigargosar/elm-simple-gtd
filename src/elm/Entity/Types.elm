module Entity.Types exposing (..)

import Document.Types exposing (DocId)
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


type EntityMsg
    = EM_StartAddingProject
    | EM_StartAddingContext
    | EM_Update EntityId EntityUpdateAction


type EntityUpdateAction
    = EUA_StartEditing
    | EUA_ToggleDeleted
    | EUA_ToggleArchived
    | EUA_SetFormText String
    | EUA_OnFocusIn
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
