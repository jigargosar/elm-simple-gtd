module GroupDoc.Types exposing (..)

import Document.Types


type alias Name =
    String


type alias Archived =
    Bool


type alias Record =
    { name : Name
    , archived : Bool
    }


type alias Model =
    Document.Types.Document Record


type alias Context =
    Model


type alias Project =
    Model
