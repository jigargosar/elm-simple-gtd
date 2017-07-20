module GroupDoc.FormTypes exposing (..)

import Document.Types exposing (DocId)
import GroupDoc.Types exposing (..)


type alias GroupDocForm =
    { id : DocId
    , groupDocType : GroupDocType
    , groupDocId : GroupDocId
    , name : GroupDocName
    , isArchived : Bool
    , mode : GroupDocFormMode
    }


type GroupDocFormMode
    = GDFM_Add
    | GDFM_Edit
