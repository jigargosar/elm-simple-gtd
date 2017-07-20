module GroupDoc.Types exposing (..)

import Document.Types exposing (DocId)
import Store.Types exposing (Store)


type GroupDocType
    = ContextGroupDocType
    | ProjectGroupDocType


type GroupDocId
    = ContextGroupDocId DocId
    | ProjectGroupDocId DocId


createGroupDocIdFromType gdType =
    case gdType of
        ContextGroupDocType ->
            ContextGroupDocId

        ProjectGroupDocType ->
            ProjectGroupDocId


type GroupDocIdAction
    = GDA_ToggleArchived
    | GDA_ToggleDeleted
    | GDA_UpdateFormName GroupDocForm GroupDocName
    | GDA_SaveForm GroupDocForm


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


type alias GroupDocName =
    String


type alias Archived =
    Bool


type alias Record =
    { name : GroupDocName
    , archived : Bool
    }


type alias GroupDoc =
    Document.Types.Document Record


type alias ContextDoc =
    GroupDoc


type alias ProjectDoc =
    GroupDoc


getGroupDocName =
    .name


isGroupDocArchived =
    .archived


type alias GroupDocStore =
    Store Record


type alias ProjectStore =
    GroupDocStore


type alias ContextStore =
    GroupDocStore
