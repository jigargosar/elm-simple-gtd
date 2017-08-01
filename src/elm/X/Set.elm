module X.Set exposing (..)

import List.Extra as List
import Maybe.Extra as Maybe
import Set
import Toolkit.Helpers exposing (..)
import Toolkit.Operators exposing (..)
import X.Function exposing (..)
import X.Function.Infix exposing (..)


toggleSetMember item set =
    if Set.member item set then
        Set.remove item set
    else
        Set.insert item set
