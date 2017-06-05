module Ext.Record exposing (..)

import Toolkit.Helpers exposing (..)
import Toolkit.Operators exposing (..)
import Ext.Function exposing (..)
import Ext.Function.Infix exposing (..)
import List.Extra as List
import Maybe.Extra as Maybe


type alias Lens small big =
    { get : big -> small, set : small -> big -> big }


type alias LensT2 small big x =
    { get : big -> small, set : ( x, small ) -> big -> ( x, big ) }


over lens smallF big =
    setIn big lens (smallF (lens.get big))


overT2 lens smallFT2 b =
    let
        ( x, s ) =
            lens.get b |> smallFT2
    in
        ( x, lens.set s b )


setIn big lens small =
    lens.set small big


createT2 getter setter =
    { get = getter, set = (\( x, s ) b -> ( x, setter s b )) }
