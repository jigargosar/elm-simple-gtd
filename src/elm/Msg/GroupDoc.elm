module Msg.GroupDoc exposing (..)

import Document.Types exposing (DocId)
import GroupDoc.FormTypes exposing (GroupDocForm)
import GroupDoc.Types exposing (..)


type GroupDocMsg
    = OnSaveGroupDocForm GroupDocForm
    | OnToggleContextDeleted DocId
    | OnToggleProjectDeleted DocId
    | OnToggleGroupDocArchived GroupDocType DocId
    | OnToggleGroupDocDeleted GroupDocType DocId
    | OnGroupDocIdAction GroupDocId GroupDocIdAction
