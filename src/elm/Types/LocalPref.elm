module Types.LocalPref exposing (..)

import AppDrawer.Model
import Firebase.SignIn


type alias LocalPref =
    { appDrawer : AppDrawer.Model.AppDrawerModel
    , signIn : Firebase.SignIn.Model
    }
