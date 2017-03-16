module Project.Model exposing (..)


type alias Project =
    { id : String
    , rev : String
    , name : String
    , isDeleted : Bool
    , note : String
    }
