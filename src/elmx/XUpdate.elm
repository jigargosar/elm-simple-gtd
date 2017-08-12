module XUpdate exposing (..)

import Maybe.Extra


type alias Return model msg otherMsg =
    ( model, List (Cmd msg), List otherMsg )


type alias ReturnF model msg otherMsg =
    Return model msg otherMsg -> Return model msg otherMsg


pure : model -> Return model msg otherMsg
pure model =
    ( model, [], [] )


addCmd : Cmd msg -> ReturnF model msg otherMsg
addCmd cmd ( model, cmdList, msgList ) =
    ( model, cmd :: cmdList, msgList )


addCmdIn : Return model msg otherMsg -> Cmd msg -> Return model msg otherMsg
addCmdIn =
    flip addCmd


addMaybeCmd : Maybe (Cmd msg) -> ReturnF model msg otherMsg
addMaybeCmd maybeCmd return =
    maybeCmd |> Maybe.map (addCmdIn return) |> Maybe.withDefault return


addMaybeCmdIn : Return model msg otherMsg -> Maybe (Cmd msg) -> Return model msg otherMsg
addMaybeCmdIn =
    flip addMaybeCmd


addMsg : otherMsg -> ReturnF model msg otherMsg
addMsg =
    List.singleton >> addMsgList


addMsgList : List otherMsg -> ReturnF model msg otherMsg
addMsgList otherMsgList ( model, cmdList, msgList ) =
    ( model, cmdList, msgList ++ otherMsgList )


map modelF ( model, cmdList, msgList ) =
    ( modelF model, cmdList, msgList )


andThen : (model -> Return model msg otherMsg) -> ReturnF model msg otherMsg
andThen fn ( model, cmdList, msgList ) =
    let
        ( newModel, newCmdList, newMsgList ) =
            fn model
    in
    ( newModel, cmdList ++ newCmdList, msgList ++ newMsgList )


maybeAddEffect fn ( model, cmdList, msgList ) =
    ( model, cmdList ++ (fn model |> Maybe.Extra.toList), msgList )


addEffect fn ( model, cmdList, msgList ) =
    ( model, cmdList ++ [ fn model ], msgList )
