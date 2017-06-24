module AppColors exposing (..)

import Toolkit.Helpers exposing (..)
import Toolkit.Operators exposing (..)
import X.Function exposing (..)
import X.Function.Infix exposing (..)
import List.Extra as List
import Maybe.Extra as Maybe


inboxColor =
    --paper-blue-a200
    "rgb(68, 138, 255)"


nullContextColor =
    inboxColor


contextsColor =
    sgtdBlue


nullProjectColor =
    --paper-deep-purple-200
    "rgb(179, 157, 219)"


projectsColor =
    --paper-deep-purple-a200
    "rgb(124, 77, 255)"


sgtdBlue =
    --paper-blue-a200
    --"rgb(68, 138, 255)"
    -- primary color
    "rgb(33, 150, 243)"


defaultGroupColor =
    --paper-grey-500
    sgtdBlue


lightGray =
    --paper-grey-500
    "#9e9e9e"
