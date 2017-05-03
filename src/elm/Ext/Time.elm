module Ext.Time exposing (..)

import Date
import Date.Extra as Date
import Date.Extra.Create exposing (getTimezoneOffset)
import Date.Format
import Ext.Date
import Time exposing (Time)
import Toolkit.Helpers exposing (..)
import Toolkit.Operators exposing (..)
import Ext.Function exposing (..)
import Ext.Function.Infix exposing (..)
import Time.Format
import Tuple2


toHHMMSS : Time -> String
toHHMMSS =
    toHMSList >> List.map (toString >> String.padLeft 2 '0') >> String.join ":"


formatDateTime =
    Time.Format.format "%a %e %b %Y %l:%M%P"


dayDiff refTime time =
    Ext.Date.dayDiff (Date.fromTime refTime) (Date.fromTime time)


dayDiffInWords =
    let
        intToDaysInWords dayCount =
            let
                dayCountAsString =
                    dayCount |> abs >> toString
            in
                if dayCount > 0 then
                    dayCountAsString ++ " days left"
                else if dayCount < 0 then
                    dayCountAsString ++ " days left"
                else
                    ""
    in
        dayDiff >>> intToDaysInWords


smartFormat : Time -> Time -> String
smartFormat refTime time =
    let
        dateFromTime =
            Date.fromTime

        refDate =
            dateFromTime refTime

        date =
            dateFromTime time
    in
        Ext.Date.smartFormat refDate date


toHMSList : Time -> List Int
toHMSList time =
    let
        elapsedMilli =
            round time

        millis =
            elapsedMilli % 1000

        seconds =
            (elapsedMilli // 1000) % (60)

        minutes =
            (elapsedMilli // (1000 * 60)) % 60

        hours =
            (elapsedMilli // (1000 * 60 * 60))
    in
        [ hours, minutes, seconds ]
