module GroupDoc.Types exposing (..)

import Document.Types


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
