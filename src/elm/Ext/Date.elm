module Ext.Date exposing (..)

import Date exposing (Date)
import Date.Extra as Date
import Date.Format as Date
import Toolkit.Helpers exposing (..)
import Toolkit.Operators exposing (..)
import Ext.Function exposing (..)
import Ext.Function.Infix exposing (..)
import List.Extra as List
import Maybe.Extra as Maybe


smartFormat : Date -> Date -> String
smartFormat refDate date =
    let
        formatTimeOfDay =
            Date.format "%l:%M%P"

        formatDateWithoutTime =
            Date.format "%e %b"

        formattedTime =
            formatTimeOfDay date |> String.trim

        formattedDate =
            formatDateWithoutTime date |> String.trim

        dayDiff =
            Date.diff Date.Day refDate date
    in
        if dayDiff == 0 then
            formattedTime
        else if dayDiff == 1 then
            "Tommorrow " ++ formattedTime
        else
            formattedDate ++ " " ++ formattedTime
