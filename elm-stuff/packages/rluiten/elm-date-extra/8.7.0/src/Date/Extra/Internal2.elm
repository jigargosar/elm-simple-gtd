module Date.Extra.Internal2 exposing (..)

{-| This module is not exposed to clients.

This module has no dependencies on any other modules in Date.Extra.
Created to alleviate circular dependency issues when fixing
`Core.toFirstOfMonth`

There is no compensation for day light saving in this modules functions.

Copyright (c) 2016-2017 Robin Luiten

-}

import Date exposing (Date, Day(..), Month(..))
import Time


{-| Epoch starting point for tick 0.
-}
epochDateStr : String
epochDateStr =
    "1970-01-01T00:00:00Z"


{-| Ticks in a millisecond. (this is 1 on Win 7 in Chrome)
-}
ticksAMillisecond : Int
ticksAMillisecond =
    floor Time.millisecond


{-| Ticks in a second.
-}
ticksASecond : Int
ticksASecond =
    ticksAMillisecond * 1000


{-| Ticks in a minute.
-}
ticksAMinute : Int
ticksAMinute =
    ticksASecond * 60


{-| Ticks in an hour.
-}
ticksAnHour : Int
ticksAnHour =
    ticksAMinute * 60


{-| Ticks in a day.
-}
ticksADay : Int
ticksADay =
    ticksAnHour * 24


{-| Ticks in a week.
-}
ticksAWeek : Int
ticksAWeek =
    ticksADay * 7


{-| Return the Iso DayOfWeek Monday 1, to Sunday 7.
-}
isoDayOfWeek : Date.Day -> Int
isoDayOfWeek day =
    case day of
        Mon ->
            1

        Tue ->
            2

        Wed ->
            3

        Thu ->
            4

        Fri ->
            5

        Sat ->
            6

        Sun ->
            7


{-| Return next day in calendar sequence.
-}
nextDay : Day -> Day
nextDay day =
    case day of
        Mon ->
            Tue

        Tue ->
            Wed

        Wed ->
            Thu

        Thu ->
            Fri

        Fri ->
            Sat

        Sat ->
            Sun

        Sun ->
            Mon


{-| Return previous day in calendar sequence.
-}
prevDay : Day -> Day
prevDay day =
    case day of
        Mon ->
            Sun

        Tue ->
            Mon

        Wed ->
            Tue

        Thu ->
            Wed

        Fri ->
            Thu

        Sat ->
            Fri

        Sun ->
            Sat


{-| Convenience fromTime as time ticks are Elm Ints in this library.
-}
fromTime : Int -> Date
fromTime =
    Date.fromTime << toFloat


{-| Convenience toTime as time ticks are Elm Ints in this library.
-}
toTime : Date -> Int
toTime =
    floor << Date.toTime


{-| List of months in order from Jan to Dec.
-}
monthList : List Month
monthList =
    [ Jan
    , Feb
    , Mar
    , Apr
    , May
    , Jun
    , Jul
    , Aug
    , Sep
    , Oct
    , Nov
    , Dec
    ]


{-| Return days in month for year month.
-}
daysInMonth : Int -> Month -> Int
daysInMonth year month =
    case month of
        Jan ->
            31

        Feb ->
            if isLeapYear year then
                29
            else
                28

        Mar ->
            31

        Apr ->
            30

        May ->
            31

        Jun ->
            30

        Jul ->
            31

        Aug ->
            31

        Sep ->
            30

        Oct ->
            31

        Nov ->
            30

        Dec ->
            31


{-| Days in month for given date.
-}
daysInMonthDate : Date -> Int
daysInMonthDate date =
    daysInMonth (Date.year date) (Date.month date)



-- go to Calendar


{-| Return True if Year is a leap year.
-}
isLeapYear : Int -> Bool
isLeapYear year =
    ((year % 4 == 0) && (year % 100 /= 0)) || ((year % 400) == 0)


{-| Return True if Year of Date is a leap year.
-}
isLeapYearDate : Date -> Bool
isLeapYearDate date =
    isLeapYear (Date.year date)


{-| Return number of days in a year.
-}
yearToDayLength : Int -> Int
yearToDayLength year =
    if isLeapYear year then
        366
    else
        365


{-| Return days in next calendar month.
-}
daysInNextMonth : Date -> Int
daysInNextMonth date =
    daysInMonthDate (firstOfNextMonthDate date)


firstOfNextMonthDate : Date -> Date
firstOfNextMonthDate date =
    fromTime ((lastOfMonthTicks date) + ticksADay)


{-| Return ticks to modify date to last day of month.
-}
lastOfMonthTicks : Date -> Int
lastOfMonthTicks date =
    let
        year =
            Date.year date

        month =
            Date.month date

        day =
            Date.day date

        dateTicks =
            toTime date

        -- _ = Debug.log("lastOfMonthTicks") (day, dateTicks)
        daysInMonthVal =
            daysInMonth year month

        addDays =
            daysInMonthVal - day
    in
        dateTicks + (addDays * ticksADay)


{-| Return last of previous month date.
This uses Internal2.firstOfMonthTicks which does no day light saving change
compensation.
-}
lastOfPrevMonthDate : Date -> Date
lastOfPrevMonthDate date =
    fromTime ((firstOfMonthTicks date) - ticksADay)


{-| Return ticks to modify date to first of month.
-}
firstOfMonthTicks : Date -> Int
firstOfMonthTicks date =
    let
        day =
            Date.day date

        dateTicks =
            toTime date
    in
        dateTicks + ((1 - day) * ticksADay)


{-| Return days in previous calendar month.
-}
daysInPrevMonth : Date -> Int
daysInPrevMonth date =
    daysInMonthDate (lastOfPrevMonthDate date)


{-| Return month as integer. Jan = 1 to Dec = 12.
-}
monthToInt : Month -> Int
monthToInt month =
    case month of
        Jan ->
            1

        Feb ->
            2

        Mar ->
            3

        Apr ->
            4

        May ->
            5

        Jun ->
            6

        Jul ->
            7

        Aug ->
            8

        Sep ->
            9

        Oct ->
            10

        Nov ->
            11

        Dec ->
            12


{-| Return integer as month. Jan <= 1 Feb == 2 up to Dec > 11.
-}
intToMonth : Int -> Month
intToMonth month =
    if (month <= 1) then
        Jan
    else if (month == 2) then
        Feb
    else if (month == 3) then
        Mar
    else if (month == 4) then
        Apr
    else if (month == 5) then
        May
    else if (month == 6) then
        Jun
    else if (month == 7) then
        Jul
    else if (month == 8) then
        Aug
    else if (month == 9) then
        Sep
    else if (month == 10) then
        Oct
    else if (month == 11) then
        Nov
    else
        Dec


{-| Return next month in calendar sequence.
-}
nextMonth : Month -> Month
nextMonth month =
    case month of
        Jan ->
            Feb

        Feb ->
            Mar

        Mar ->
            Apr

        Apr ->
            May

        May ->
            Jun

        Jun ->
            Jul

        Jul ->
            Aug

        Aug ->
            Sep

        Sep ->
            Oct

        Oct ->
            Nov

        Nov ->
            Dec

        Dec ->
            Jan


{-| Return previous month in calendar sequence.
-}
prevMonth : Month -> Month
prevMonth month =
    case month of
        Jan ->
            Dec

        Feb ->
            Jan

        Mar ->
            Feb

        Apr ->
            Mar

        May ->
            Apr

        Jun ->
            May

        Jul ->
            Jun

        Aug ->
            Jul

        Sep ->
            Aug

        Oct ->
            Sep

        Nov ->
            Oct

        Dec ->
            Nov
