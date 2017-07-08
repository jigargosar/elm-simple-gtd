module Entity.Types exposing (..)

import Document.Types
import GroupDoc.Types
import Todo
import Types


type GroupEntity
    = Project GroupDoc.Types.Model
    | Context GroupDoc.Types.Model


type Entity
    = Group GroupEntity
    | Todo Todo.Model


type ListViewType
    = ContextsView
    | ContextView Types.DocId
    | ProjectsView
    | ProjectView Types.DocId
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
