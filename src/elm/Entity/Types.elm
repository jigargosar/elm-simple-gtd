module Entity.Types exposing (..)

import Document.Types exposing (DocId)
import GroupDoc.Types
import Todo.Types


type GroupEntity
    = Project GroupDoc.Types.Model
    | Context GroupDoc.Types.Model


type Entity
    = Group GroupEntity
    | Todo Todo.Types.Model


type ListViewType
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
