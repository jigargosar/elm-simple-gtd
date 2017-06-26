module ActionList exposing (..)

import Menu











type alias Model =
    { menuState : Menu.State
    , searchText : String
    }


init =
    { menuState = Menu.initState
    , searchText = ""
    }
