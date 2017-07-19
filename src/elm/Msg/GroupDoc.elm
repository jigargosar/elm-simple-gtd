module Msg.GroupDoc exposing (..)

import Document.Types exposing (DocId)
import GroupDoc.FormTypes exposing (GroupDocForm)
import GroupDoc.Types


type GroupDocMsg
    = OnSaveGroupDocForm GroupDocForm
    | OnToggleContextArchived DocId
    | OnToggleProjectArchived DocId
    | OnToggleContextDeleted DocId
    | OnToggleProjectDeleted DocId
    | OnToggleGroupDocArchived GroupDoc.Types.GroupDocType DocId
    | OnToggleGroupDocDeleted GroupDoc.Types.GroupDocType DocId
