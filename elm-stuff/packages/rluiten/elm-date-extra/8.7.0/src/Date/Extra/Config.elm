module Date.Extra.Config exposing (..)

{-| Date configuration.

For i18n for day and month names.
Parameter to Format.format* functions.

There is scope to put in some default format strings here.

@docs Config

Copyright (c) 2016-2017 Robin Luiten

-}

import Date exposing (Day, Month)


{-| Configuration for formatting dates.
-}
type alias Config =
    { i18n :
        { dayShort : Day -> String
        , dayName : Day -> String
        , monthShort : Month -> String
        , monthName : Month -> String
        , dayOfMonthWithSuffix : Bool -> Int -> String
        }
    , format :
        { date : String
        , longDate : String
        , time : String
        , longTime : String
        , dateTime : String
        , firstDayOfWeek : Date.Day
        }
    }
