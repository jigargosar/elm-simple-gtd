module Ext.List exposing (..)

import Toolkit.Helpers exposing (..)
import Toolkit.Operators exposing (..)
import Ext.Function exposing (..)
import Ext.Function.Infix exposing (..)
import List.Extra as List
import Maybe.Extra as Maybe


listLastIndex list =
    case list of
        [] ->
            0

        _ ->
            (List.length list) - 1


clampIndex index =
    listLastIndex >> clamp 0 # index


prependIn =
    flip (::)


toMaybe list =
    case list of
        [] ->
            Nothing

        _ ->
            Just list
