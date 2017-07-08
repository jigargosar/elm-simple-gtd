module Entity.Types exposing (..)

import Document.Types exposing (DocId)
import GroupDoc.Types
import Todo.Types


type GroupEntityType
    = ProjectEntity GroupDoc.Types.GroupDoc
    | ContextEntity GroupDoc.Types.GroupDoc


type EntityType
    = GroupEntity GroupEntityType
    | TodoEntity Todo.Types.TodoDoc


type EntityListViewType
    = ContextsView
    | ContextView DocId
    | ProjectsView
    | ProjectView DocId
    | BinView
    | DoneView
    | RecentView


type Msg
    = OnStartEditing
    | OnToggleDeleted
    | OnToggleArchived
    | OnSave
    | OnNameChanged String
    | OnOnFocusIn
    | OnToggleSelected
    | OnGoto


createContextEntity =
    ContextEntity >> GroupEntity


createProjectEntity =
    ProjectEntity >> GroupEntity
