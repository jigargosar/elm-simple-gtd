module Main.Update exposing (..)

import Context
import Entity.Types exposing (Entity(GroupEntity), GroupEntityType(ContextEntity), createContextEntity)
import ExclusiveMode.Types exposing (ExclusiveMode(XMSetup, XMSignInOverlay))
import Firebase.SignIn
import Model.Internal exposing (deactivateEditingMode, setExclusiveMode)
import Msg exposing (MainMsg(OnSwitchToNewUserSetupModeIfNeeded), Msg)
import Return exposing (map)
import Store
import Todo.Form
import Todo.FormTypes exposing (..)
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
                    model
                        |> if Firebase.SignIn.shouldSkipSignIn model.signInModel then
                            if Store.isEmpty model.todoStore then
                                setExclusiveMode createSetupExclusiveMode
                            else
                                deactivateEditingMode
                           else
                            setExclusiveMode XMSignInOverlay

                inboxEntity =
                    createContextEntity Context.null

                createSetupExclusiveMode =
                    XMSetup (Todo.Form.createNewTodoForm NTFM_SetupFirstTodo inboxEntity "")
            in
                map onSwitchToNewUserSetupModeIfNeeded
