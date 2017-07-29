module GroupDoc.Types exposing (..)

import Store exposing (Store)
import Types.Document exposing (..)


type GroupDocType
    = ContextGroupDocType
    | ProjectGroupDocType


type GroupDocId
    = ContextGroupDocId DocId
    | ProjectGroupDocId DocId


type GroupDocAction
    = GDA_StartAdding


type GroupDocIdAction
    = GDA_StartEditing
    | GDA_ToggleArchived
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
    Document.Document Record


type alias ContextDoc =
    GroupDoc


type alias ProjectDoc =
    GroupDoc


type alias GroupDocStore =
    Store Record


type alias ProjectStore =
    GroupDocStore


type alias ContextStore =
    GroupDocStore
