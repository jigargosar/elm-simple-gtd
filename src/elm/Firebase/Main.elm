port module Firebase.Main exposing (..)

import Firebase
import Model
import Return
import Toolkit.Helpers exposing (..)
import Toolkit.Operators exposing (..)
import X.Function exposing (..)
import X.Function.Infix exposing (..)
import List.Extra as List
import Maybe.Extra as Maybe
import Time


port signIn : () -> Cmd msg


update :
    (Model.Msg -> Model.ReturnF)
    -> Time.Time
    -> Firebase.Msg
    -> Model.ReturnF
update andThenUpdate now msg =
    case msg of
        Firebase.OnSignIn ->
            Return.command (signIn ())
                >> andThenUpdate Model.OnDeactivateEditingMode
