module CommonMsg.Types exposing (..)


type alias DomSelector =
    String


type Msg
    = NoOp
    | Focus DomSelector
    | LogString String
