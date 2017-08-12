module XUpdate exposing (..)


type alias PartReturn model msg otherMsg =
    ( model, List (Cmd msg), List otherMsg )


type alias PartReturnF model msg otherMsg =
    PartReturn model msg otherMsg -> PartReturn model msg otherMsg


pure : model -> PartReturn model msg otherMsg
pure model =
    ( model, [], [] )


addCmd : Cmd msg -> PartReturnF model msg otherMsg
addCmd cmd ( model, cmdList, msgList ) =
    ( model, cmd :: cmdList, msgList )


addMsg : otherMsg -> PartReturnF model msg otherMsg
addMsg otherMsg ( model, cmdList, msgList ) =
    ( model, cmdList, msgList ++ [ otherMsg ] )


