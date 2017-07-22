module X.Time exposing (..)

import Date
import List.Extra
import Time exposing (Time)
import Time.Format
import X.Date
import X.Function exposing (..)
import X.Function.Infix exposing (..)


toHHMMSS : Time -> String
toHHMMSS =
    toHMSList >> List.map (toString >> String.padLeft 2 '0') >> String.join ":"


toHHMMSSMin : Time -> String
toHHMMSSMin =
    let
        suffixList =
            [ "h", "m", "s" ]

        tupleToString ( suffix, part ) =
            toString part ++ suffix
    in
    toHMSList
        >> List.Extra.zip suffixList
        >> List.filterMap
            (ifElse (Tuple.second >> equals 0) (\_ -> Nothing) (tupleToString >> Just))
        >> String.join " "


formatDateTime =
    Time.Format.format "%a %e %b %Y %l:%M%P"


dayDiff : Time -> Time -> Int
dayDiff refTime time =
    X.Date.dayDiff (Date.fromTime refTime) (Date.fromTime time)


dayDiffInWords : Time -> Time -> String
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
                dayCountAsString ++ " days ago"
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
    X.Date.smartFormat refDate date


toHMSList : Time -> List Int
toHMSList time =
    let
        elapsedMilli =
            round time

        millis =
            elapsedMilli % 1000

        seconds =
            (elapsedMilli // 1000) % 60

        minutes =
            (elapsedMilli // (1000 * 60)) % 60

        hours =
            elapsedMilli // (1000 * 60 * 60)
    in
    [ hours, minutes, seconds ]
