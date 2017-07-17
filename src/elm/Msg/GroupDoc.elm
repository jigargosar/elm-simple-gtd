module Msg.GroupDoc exposing (..)

import Document.Types exposing (DocId)
import GroupDoc.FormTypes exposing (GroupDocForm)


type GroupDocMsg
    = OnSaveGroupDocForm GroupDocForm
    | OnToggleContextArchived DocId
    | OnToggleProjectArchived DocId
    | OnToggleContextDeleted DocId
    | OnToggleProjectDeleted DocId
