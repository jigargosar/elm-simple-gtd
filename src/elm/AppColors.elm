module AppColors exposing (..)

import Color
import CssBasics
import Toolkit.Helpers exposing (..)
import Toolkit.Operators exposing (..)
import X.Function exposing (..)
import X.Function.Infix exposing (..)
import List.Extra as List
import Maybe.Extra as Maybe


inboxColor =
    nullContextColor


nullContextColor =
    Color.rgb 68 138 255


contextsColor =
    sgtdBlue


defaultContextColor =
    contextsColor


nullProjectColor =
    Color.rgb 179 157 219


projectsColor =
    Color.rgb 124 77 255


defaultProjectColor =
    projectsColor


sgtdBlue =
    Color.rgb 33 150 243


defaultGroupColor =
    sgtdBlue


encode =
    CssBasics.Col >> CssBasics.encodeCssValue
