module Date.Internal.Extract exposing
  ( monthNumber
  , quarter
  , ordinalDay
  , fractionalDay
  , weekdayNumber
  , weekNumber
  , weekYear
  , offsetFromUtc
  )

import Date exposing (Date, Month(..), toTime, year, month, day, hour, minute, second, millisecond, dayOfWeek)
import Date.Extra.Facts exposing (monthNumberFromMonth, weekdayNumberFromDayOfWeek, daysBeforeStartOfMonth, msPerMinute, msPerDay)
import Date.Internal.Core exposing (unixTimeFromParts, weekYearFromCalendarDate, weekNumberFromCalendarDate, msFromTimeParts)


monthNumber : Date -> Int
monthNumber =
  monthNumberFromMonth << month


quarter : Date -> Int
quarter date =
  monthNumber date |> toFloat |> (\n -> n / 3) |> ceiling


ordinalDay : Date -> Int
ordinalDay date =
  daysBeforeStartOfMonth (year date) (month date) + day date


fractionalDay : Date -> Float
fractionalDay date =
  let
    timeOfDayMS = msFromTimeParts (hour date) (minute date) (second date) (millisecond date)
  in
    toFloat timeOfDayMS / toFloat msPerDay


weekdayNumber : Date -> Int
weekdayNumber =
  weekdayNumberFromDayOfWeek << dayOfWeek


weekNumber : Date -> Int
weekNumber date =
  weekNumberFromCalendarDate (year date) (month date) (day date)


weekYear : Date -> Int
weekYear date =
  weekYearFromCalendarDate (year date) (month date) (day date)


msOffsetFromUtc : Date -> Int
msOffsetFromUtc date =
  let
    localTime = toFloat <| unixTimeFromParts (year date) (month date) (day date) (hour date) (minute date) (second date) (millisecond date)
    utcTime = toTime date
  in
    localTime - utcTime |> floor


offsetFromUtc : Date -> Int
offsetFromUtc date =
  msOffsetFromUtc date // msPerMinute
