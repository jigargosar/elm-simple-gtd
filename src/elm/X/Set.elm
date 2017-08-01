module X.Set exposing (..)

import Set


toggleSetMember item set =
    if Set.member item set then
        Set.remove item set
    else
        Set.insert item set
