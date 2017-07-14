module GroupDoc.FormTypes exposing (..)

import Document.Types exposing (DocId)
import Entity.Types exposing (Entity)
import GroupDoc.Types exposing (..)


type alias GroupDocForm =
    { id : DocId
    , name : GroupDocName
    , groupDocType : GroupDocType
    , isArchived : Bool
    , mode : GroupDocFormMode
    }


type GroupDocFormMode
    = GDFM_Add
    | GDFM_Edit
