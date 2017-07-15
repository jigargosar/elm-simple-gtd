module LocalPref.Types exposing (..)

import AppDrawer.Model
import Firebase.SignIn
import Toolkit.Helpers exposing (..)
import Toolkit.Operators exposing (..)
import X.Function exposing (..)
import X.Function.Infix exposing (..)
import List.Extra as List
import Maybe.Extra as Maybe


type alias LocalPref =
    { appDrawer : AppDrawer.Model.Model
    , signIn : Firebase.SignIn.Model
    }
