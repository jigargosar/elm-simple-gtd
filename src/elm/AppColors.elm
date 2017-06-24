module AppColors exposing (..)

import Color
import CssBasics
import Toolkit.Helpers exposing (..)
import Toolkit.Operators exposing (..)
import X.Function exposing (..)
import X.Function.Infix exposing (..)
import List.Extra as List
import Maybe.Extra as Maybe


primaryColor =
    Color.rgb 68 138 255


sgtdBlue =
    Color.rgb 33 150 243


nullContextColor =
    sgtdBlue


contextsColor =
    primaryColor


defaultContextColor =
    contextsColor


nullProjectColor =
    Color.rgb 179 157 219


projectsColor =
    Color.rgb 124 77 255


defaultProjectColor =
    projectsColor


encode =
    CssBasics.Col >> CssBasics.encodeCssValue
