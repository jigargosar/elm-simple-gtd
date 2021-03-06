module X.List exposing (..)

import List.Extra
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


findIndex =
    List.Extra.findIndex


getAtIndexIn =
    flip List.Extra.getAt


clampAndGetAtIndex index list =
    clampIndex index list
        |> getAtIndexIn list


clampAndGetAtIndexIn =
    flip clampAndGetAtIndex


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


findIndexIn =
    flip List.Extra.findIndex


firstIndexOf val list =
    List.Extra.findIndex ((==) val) list


firstIndexOfIn =
    flip firstIndexOf
