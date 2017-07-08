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


type alias Context =
    GroupDoc


type alias Project =
    GroupDoc


getGroupDocName =
    .name


isGroupDocArchived =
    .archived
