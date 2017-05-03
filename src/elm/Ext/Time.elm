module Ext.Time exposing (..)

import Date
import Date.Extra as Date
import Date.Format
import Time exposing (Time)
import Toolkit.Helpers exposing (..)
import Toolkit.Operators exposing (..)
import Ext.Function exposing (..)
import Time.Format


--toHHMMSS : Time -> String
--toHHMMSS time =
--    let
--        roundToFloat =
--            round >> toFloat
--
--        roundToString =
--            round >> toString
--
--        secondsMilli =
--            time / Time.second |> roundToFloat |> (*) Time.second
--
--        minutesMilli =
--            time / Time.minute |> roundToFloat |> (*) Time.minute
--
--        hoursMilli =
--            time / Time.hour |> roundToFloat |> (*) Time.hour
--
--        seconds =
--            abs (secondsMilli - minutesMilli) / Time.second |> roundToString
--
--        --        seconds =
--        --            rem (round time) (round Time.second) |> toString
--        minutes =
--            abs (minutesMilli - hoursMilli) / Time.minute |> roundToString
--
--        hours =
--            (hoursMilli) / Time.hour |> roundToString
--    in
--        [ hours, minutes, seconds ] |> String.join ":"


toHHMMSS : Time -> String
toHHMMSS =
    toHMSList >> List.map (toString >> String.padLeft 2 '0') >> String.join ":"


formatDateTime =
    Time.Format.format "%e %b %l:%M%P"


smartFormat : Time -> Time -> String
smartFormat refTime time =
    let
        formatTimeOfDay =
            Date.Format.format "%l:%M%P"

        formatDateWithoutTime =
            Date.Format.format "%e %b"

        refDate =
            Date.fromTime refTime

        date =
            Date.fromTime time

        formattedTime =
            formatTimeOfDay date |> String.trim

        formattedDate =
            formatDateWithoutTime date |> String.trim
    in
        if Date.equalBy Date.Day refDate date then
            formattedTime
        else
            formattedDate ++ " " ++ formattedTime


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
