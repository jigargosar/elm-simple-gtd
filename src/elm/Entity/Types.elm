module Entity.Types exposing (..)

import Context
import Document.Types
import Project
import Todo


type GroupEntity
    = Project Project.Model
    | Context Context.Model


type Entity
    = Group GroupEntity
    | Todo Todo.Model


type ListViewType
    = ContextsView
    | ContextView Document.Types.Id
    | ProjectsView
    | ProjectView Document.Types.Id
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
