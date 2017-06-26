module X.List exposing (..)


import Toolkit.Operators exposing (..)


import List.Extra as List



listLastIndex list =
    case list of
        [] ->
            0

        _ ->
            (List.length list) - 1


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
