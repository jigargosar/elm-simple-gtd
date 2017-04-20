module WebComponents exposing (..)

import Html
import Html.Attributes.Extra exposing (stringProperty)
import Toolkit.Helpers exposing (..)
import Toolkit.Operators exposing (..)
import Ext.Function exposing (..)
import Ext.Function.Infix exposing (..)
import List.Extra as List
import Maybe.Extra as Maybe


ironIcon_ =
    Html.node "iron-icon"


ironIcon icon_ attributes =
    ironIcon_ (attributes ++ [ stringProperty "icon" icon_ ]) []
