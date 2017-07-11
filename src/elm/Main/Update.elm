module Main.Update exposing (..)

import Context
import Entity.Types exposing (Entity(GroupEntity), GroupEntityType(ContextEntity), createContextEntity)
import ExclusiveMode
import ExclusiveMode.Types exposing (ExclusiveMode(XMSetup))
import Firebase.SignIn
import Model.ExMode
import Model.Internal exposing (setEditMode)
import Msg exposing (MainMsg(OnSwitchToNewUserSetupModeIfNeeded), Msg)
import Return exposing (map)
import Store
import Todo.NewForm
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
                                setEditMode createSetupExclusiveMode
                            else
                                Model.ExMode.deactivateEditingMode
                           else
                            setEditMode ExclusiveMode.signInOverlay

                inboxEntity =
                    createContextEntity Context.null

                createSetupExclusiveMode =
                    XMSetup (Todo.NewForm.create inboxEntity "")
            in
                map onSwitchToNewUserSetupModeIfNeeded
