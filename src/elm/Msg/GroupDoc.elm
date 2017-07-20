module Msg.GroupDoc exposing (..)

import Document.Types exposing (DocId)
import GroupDoc.Types exposing (GroupDocForm)
import GroupDoc.Types exposing (..)


type GroupDocMsg
    = OnSaveGroupDocForm GroupDocForm
    | OnToggleContextDeleted DocId
    | OnToggleProjectDeleted DocId
    | OnGroupDocIdAction GroupDocId GroupDocIdAction
