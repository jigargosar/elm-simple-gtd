module XUpdate exposing (..)


type alias XReturn model msg otherMsg =
    ( model, List (Cmd msg), List otherMsg )


type alias XReturnF model msg otherMsg =
    XReturn model msg otherMsg -> XReturn model msg otherMsg


pure : model -> XReturn model msg otherMsg
pure model =
    ( model, [], [] )


addCmd : Cmd msg -> XReturnF model msg otherMsg
addCmd cmd ( model, cmdList, msgList ) =
    ( model, cmd :: cmdList, msgList )


addMsg : otherMsg -> XReturnF model msg otherMsg
addMsg otherMsg ( model, cmdList, msgList ) =
    ( model, cmdList, msgList ++ [ otherMsg ] )


--andThen modelF  ( model, cmdList, msgList ) =
