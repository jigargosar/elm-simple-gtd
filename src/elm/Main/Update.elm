module Main.Update exposing (..)

import ExclusiveMode.Types exposing (ExclusiveMode(..))
import Firebase.SignIn
import Model.Internal exposing (deactivateEditingMode, setExclusiveMode)
import Msg exposing (MainMsg(OnSwitchToNewUserSetupModeIfNeeded), Msg)
import Return exposing (map)
import Store
import TodoMsg
import Types exposing (ReturnF)


update :
    (Msg -> ReturnF)
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
                                andThenUpdate Msg.OnDeactivateEditingMode
                           else
                            map (setExclusiveMode XMSignInOverlay)
            in
                Return.andThen onSwitchToNewUserSetupModeIfNeeded
