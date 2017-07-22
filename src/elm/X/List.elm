module X.List exposing (..)

import List.Extra as List
import Toolkit.Operators exposing (..)


listLastIndex list =
    case list of
        [] ->
            0

        _ ->
            List.length list - 1


clampIndex index =
    listLastIndex >> clamp 0 # index


clampIndexIn =
    flip clampIndex


atIndexIn =
    flip List.getAt


prependIn =
    flip (::)


toMaybe list =
    case list of
        [] ->
            Nothing

        _ ->
            Just list


singleton item =
    [ item ]
