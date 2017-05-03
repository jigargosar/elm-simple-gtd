module Ext.Time exposing (..)

import Date
import Date.Extra as Date
import Date.Format
import Ext.Date
import Time exposing (Time)
import Toolkit.Helpers exposing (..)
import Toolkit.Operators exposing (..)
import Ext.Function exposing (..)
import Ext.Function.Infix exposing (..)
import Time.Format
import Tuple2


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
        refDate =
            Date.fromTime refTime

        date =
            Date.fromTime time
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
