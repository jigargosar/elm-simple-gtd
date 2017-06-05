module Ext.Record exposing (..)

import Toolkit.Helpers exposing (..)
import Toolkit.Operators exposing (..)
import Ext.Function exposing (..)
import Ext.Function.Infix exposing (..)
import List.Extra as List
import Maybe.Extra as Maybe


type alias LensRec small big =
    { get : big -> small, set : small -> big -> big }


type Lens small big
    = Lens (LensRec small big)


init : (big -> small) -> (small -> big -> big) -> Lens small big
init getter setter =
    Lens { get = getter, set = setter }


get (Lens lens) big =
    lens.get big


set (Lens lens) small big =
    lens.set small big


over lens smallF big =
    setIn big lens (smallF (get lens big))


setIn big lens small =
    set lens small big


overT2 (Lens lens) smallFT2 b =
    let
        ( x, s ) =
            lens.get b |> smallFT2
    in
        ( x, lens.set s b )
