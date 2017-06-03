module LaunchBar.Form exposing (..)

import Char
import Keyboard.Extra
import Toolkit.Helpers exposing (..)
import Toolkit.Operators exposing (..)
import Ext.Function exposing (..)
import Ext.Function.Infix exposing (..)
import List.Extra as List
import Maybe.Extra as Maybe


_ =
    1


type alias Model =
    { input : String }


create =
    { input = "" }


updateInput input model =
    { model | input = input }
