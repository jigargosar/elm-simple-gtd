module LocalPref.Types exposing (..)

import AppDrawer.Model
import Firebase.SignIn


type alias LocalPref =
    { appDrawer : AppDrawer.Model.Model
    , signIn : Firebase.SignIn.Model
    }
