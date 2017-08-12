module XUpdate exposing (..)


type alias XReturn model msg otherMsg =
    ( model, List (Cmd msg), List otherMsg )


type alias XReturnF model msg otherMsg =
    XReturn model msg otherMsg -> XReturn model msg otherMsg


pure : model -> XReturn model msg otherMsg
pure model =
    ( model, [], [] )

--map: (model -> model) -> XReturnF model msg otherMsg
--map modelF model msg otherMsg =



addCmd : Cmd msg -> XReturnF model msg otherMsg
addCmd cmd ( model, cmdList, msgList ) =
    ( model, cmd :: cmdList, msgList )

addCmdIn : XReturn model msg otherMsg -> Cmd msg -> XReturn model msg otherMsg
addCmdIn  =
    flip addCmd

addMaybeCmd : Maybe (Cmd msg) -> XReturnF model msg otherMsg
addMaybeCmd maybeCmd return =
    maybeCmd |> Maybe.map (addCmdIn return) |> Maybe.withDefault return

addMaybeCmdIn : XReturn model msg otherMsg -> Maybe (Cmd msg) -> XReturn model msg otherMsg
addMaybeCmdIn =
    flip addMaybeCmd


addMsg : otherMsg -> XReturnF model msg otherMsg
addMsg =
    List.singleton >> addMsgList

addMsgList : List otherMsg -> XReturnF model msg otherMsg
addMsgList otherMsgList ( model, cmdList, msgList ) =
    ( model, cmdList, msgList ++ otherMsgList )


map modelF  ( model, cmdList, msgList ) =
    ( modelF model, cmdList, msgList )
