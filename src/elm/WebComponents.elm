module WebComponents exposing (..)

import Html
import Html.Attributes.Extra exposing (stringProperty)
import Toolkit.Helpers exposing (..)
import Toolkit.Operators exposing (..)
import Ext.Function exposing (..)
import Ext.Function.Infix exposing (..)
import List.Extra as List
import Maybe.Extra as Maybe


ironIcon =
    Html.node "iron-icon"


iconP =
    stringProperty "icon"


icon iconName attributes =
    ironIcon (attributes ++ [ iconP iconName ]) []


paperIconButton =
    Html.node "paper-icon-button"


iconButton iconName attributes =
    paperIconButton (attributes ++ [ iconP iconName ])


doneAllIconP =
    iconP "done-all"
