module ActionList exposing (..)

import Menu
import Toolkit.Helpers exposing (..)
import Toolkit.Operators exposing (..)
import X.Function exposing (..)
import X.Function.Infix exposing (..)
import List.Extra
import Maybe.Extra
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)


type alias Model =
    { menuState : Menu.State
    , searchText : String
    }


init =
    { menuState = Menu.initState
    , searchText = ""
    }
