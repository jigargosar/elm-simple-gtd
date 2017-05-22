module Date.Extra.Internal exposing (..)

{-| This module is not exposed to clients.

Copyright (c) 2016-2017 Robin Luiten

-}

import Date exposing (Date, Month(..))
import Date.Extra.Period as Period
import Date.Extra.Internal2 as Internal2


{-| Adjust date as if it was in utc zone.
-}
hackDateAsUtc : Date -> Date
hackDateAsUtc date =
    let
        offset =
            getTimezoneOffset date

        oHours =
            offset // Internal2.ticksAnHour

        oMinutes =
            (offset - (oHours * Internal2.ticksAnHour)) // Internal2.ticksAMinute
    in
        hackDateAsOffset offset date


{-| Adjust date for time zone offset in minutes.
-}
hackDateAsOffset : Int -> Date -> Date
hackDateAsOffset offsetMinutes date =
    Internal2.toTime date
        |> (+) (offsetMinutes * Internal2.ticksAMinute)
        |> Internal2.fromTime


{-| Returns number of days since civil 1970-01-01. Negative values indicate
days prior to 1970-01-01.

Reference: <http://stackoverflow.com/questions/7960318/math-to-convert-seconds-since-1970-into-date-and-vice-versa>
Which references: <http://howardhinnant.github.io/date_algorithms.html>

-}
daysFromCivil : Int -> Int -> Int -> Int
daysFromCivil year month day =
    let
        y =
            year
                - if month <= 2 then
                    1
                  else
                    0

        era =
            (if y >= 0 then
                y
             else
                y - 399
            )
                // 400

        yoe =
            y - (era * 400)

        -- [0, 399]
        doy =
            (153
                * (month
                    + (if month > 2 then
                        -3
                       else
                        9
                      )
                  )
                + 2
            )
                // 5
                + day
                - 1

        -- [0, 365]
        doe =
            yoe * 365 + yoe // 4 - yoe // 100 + doy

        -- [0, 146096]
    in
        era * 146097 + doe - 719468


{-| See comment in `Create.getTimezoneOffset`
-}
getTimezoneOffset : Date -> Int
getTimezoneOffset date =
    let
        dateTicks =
            floor (Date.toTime date)

        v1Ticks =
            ticksFromDateFields date
    in
        (dateTicks - v1Ticks) // Internal2.ticksAMinute


ticksFromDateFields : Date -> Int
ticksFromDateFields date =
    ticksFromFields
        (Date.year date)
        (Date.month date)
        (Date.day date)
        (Date.hour date)
        (Date.minute date)
        (Date.second date)
        (Date.millisecond date)


ticksFromFields : Int -> Month -> Int -> Int -> Int -> Int -> Int -> Int
ticksFromFields year month day hour minute second millisecond =
    let
        clampYear =
            if year < 0 then
                0
            else
                year

        monthInt =
            Internal2.monthToInt month

        clampDay =
            clamp 1 (Internal2.daysInMonth clampYear month) day

        dayCount =
            daysFromCivil clampYear monthInt clampDay
    in
        Period.toTicks <|
            Period.Delta
                { millisecond = (clamp 0 999 millisecond)
                , second = (clamp 0 59 second)
                , minute = (clamp 0 59 minute)
                , hour = (clamp 0 23 hour)
                , day = dayCount
                , week = 0
                }
