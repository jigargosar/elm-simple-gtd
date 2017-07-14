module GroupDoc.FormTypes exposing (..)

import Document.Types exposing (DocId)
import Entity.Types exposing (Entity)
import GroupDoc.Types exposing (..)


type alias GroupDocEditForm =
    { id : DocId
    , name : GroupDocName
    , groupDocType : GroupDocType
    , isArchived : Bool
    }
