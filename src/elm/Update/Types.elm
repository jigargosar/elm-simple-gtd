module Update.Types exposing (..)

import Return
import Toolkit.Helpers exposing (..)
import Toolkit.Operators exposing (..)
import X.Function exposing (..)
import X.Function.Infix exposing (..)
import List.Extra as List
import Maybe.Extra as Maybe
import Types exposing (AppModel)


type alias SubReturnF msg =
    Return.ReturnF msg AppModel
