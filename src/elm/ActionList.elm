module ActionList exposing (..)

import Menu
import Toolkit.Helpers exposing (..)
import Toolkit.Operators exposing (..)
import Ext.Function exposing (..)
import Ext.Function.Infix exposing (..)
import List.Extra as List
import Maybe.Extra as Maybe
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Html.Events.Extra exposing (onClickStopPropagation)


type alias Model =
    { menuState : Menu.State
    , searchText : String
    }


init =
    { menuState = Menu.initState
    , searchText = ""
    }
