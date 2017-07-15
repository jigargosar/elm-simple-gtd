module Main.Update exposing (..)

import ExclusiveMode.Types exposing (ExclusiveMode(..))
import Firebase.SignIn
import Msg exposing (MainMsg(..), AppMsg)
import Return exposing (map)
import Store
import TodoMsg
import Types exposing (ReturnF)
import Update.ExclusiveMode
import XMMsg


update :
    (AppMsg -> ReturnF)
    -> MainMsg
    -> ReturnF
update andThenUpdate msg =
    case msg of
        OnSwitchToNewUserSetupModeIfNeeded ->
            let
                onSwitchToNewUserSetupModeIfNeeded model =
                    Return.singleton model
                        |> if Firebase.SignIn.shouldSkipSignIn model.signInModel then
                            if Store.isEmpty model.todoStore then
                                andThenUpdate TodoMsg.onStartSetupAddTodo
                            else
                                andThenUpdate XMMsg.onSetExclusiveModeToNoneAndTryRevertingFocus
                           else
                            andThenUpdate (XMMsg.onSetExclusiveMode XMSignInOverlay)
            in
                Return.andThen onSwitchToNewUserSetupModeIfNeeded

        OnExclusiveModeMsg msg_ ->
            Update.ExclusiveMode.update andThenUpdate msg_
