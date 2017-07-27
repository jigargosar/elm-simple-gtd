module EntityList exposing (..)

import EntityList.Types exposing (EntityList)
import List.Extra as List
import Maybe.Extra as Maybe
import Toolkit.Helpers exposing (..)
import Toolkit.Operators exposing (..)
import X.Function exposing (..)
import X.Function.Infix exposing (..)


initialValue : EntityList
initialValue =
    { idList = []
    , maybeFocusableEntityId = Nothing
    }
