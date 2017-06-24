module AppColors exposing (..)

import Color
import Color.Mixing
import CssBasics
import Toolkit.Helpers exposing (..)
import Toolkit.Operators exposing (..)
import X.Function exposing (..)
import X.Function.Infix exposing (..)
import List.Extra as List
import Maybe.Extra as Maybe


-- base colors


primaryColor =
    Color.rgb 68 138 255


sgtdBlue =
    Color.rgb 33 150 243



-- group colors


contextsColor =
    primaryColor


nullContextColor =
    sgtdBlue


defaultContextColor =
    mixDefaultGroupColor contextsColor


projectsColor =
    Color.rgb 124 77 255


nullProjectColor =
    Color.rgb 179 157 219


defaultProjectColor =
    mixDefaultGroupColor projectsColor


mixDefaultGroupColor =
    Color.Mixing.fadeIn 0.1


mixNullGroupColor =
    Color.Mixing.fadeIn 0.1



-- util


encode =
    CssBasics.Col >> CssBasics.encodeCssValue
