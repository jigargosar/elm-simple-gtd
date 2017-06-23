module Date.Distance
    exposing
        ( inWords
        , inWordsWithConfig
        , defaultConfig
        )

{-|
# Basics
@docs inWords

# Custom Config
@docs inWordsWithConfig
@docs defaultConfig
-}

import Date.Distance.I18n.En as English
import Date.Distance.Types exposing (..)
import Date exposing (Month(..))
import Date.Extra as Date exposing (Interval(..))


minutes_in_day : number
minutes_in_day =
    1440


minutes_in_almost_two_days : number
minutes_in_almost_two_days =
    2520


minutes_in_month : number
minutes_in_month =
    43200


minutes_in_two_months : number
minutes_in_two_months =
    86400


{-| Returns the distance between two dates in words.

    date1 = Date.fromParts 2017 May 5 10 20 0 0
    date2 = Date.fromParts 2017 May 7 10 20 0 0

    inWords date1 date2 == "2 days"
-}
inWords :
    Date.Date
    -> Date.Date
    -> String
inWords =
    inWordsWithConfig defaultConfig


{-| Default configuration. Use with `inWordsWithConfig`.
-}
defaultConfig : Config
defaultConfig =
    { locale = English.locale { addSuffix = False }
    , includeSeconds = False
    }


{-| Like `inWords` but configurable.

    inWords = { defaultConfig | includeSeconds = True }
        |> inWordsWithConfig

    -- use it
    inWords date1 date2

Read the documentation on `Config` for a full run down
of the available options.
-}
inWordsWithConfig :
    Config
    -> Date.Date
    -> Date.Date
    -> String
inWordsWithConfig { locale, includeSeconds } d1 d2 =
    let
        order =
            Date.compare d1 d2

        ( fst, snd ) =
            if order == LT then
                ( d1, d2 )
            else
                ( d2, d1 )

        localize =
            locale order

        distance =
            calculateDistance includeSeconds fst snd
    in
        localize distance


upToOneMinute : Int -> DistanceLocale
upToOneMinute seconds =
    if seconds < 5 then
        LessThanXSeconds 5
    else if seconds < 10 then
        LessThanXSeconds 10
    else if seconds < 20 then
        LessThanXSeconds 20
    else if seconds < 40 then
        HalfAMinute
    else if seconds < 60 then
        LessThanXMinutes 1
    else
        XMinutes 1


upToOneDay : Int -> DistanceLocale
upToOneDay minutes =
    let
        hours =
            round <| toFloat minutes / 60
    in
        AboutXHours hours


upToOneMonth : Int -> DistanceLocale
upToOneMonth minutes =
    let
        days =
            round <| toFloat minutes / minutes_in_day
    in
        XDays days


upToTwoMonths : Int -> DistanceLocale
upToTwoMonths minutes =
    let
        months =
            round <| toFloat minutes / minutes_in_month
    in
        AboutXMonths months


upToOneYear : Int -> DistanceLocale
upToOneYear minutes =
    let
        nearestMonth =
            round <| toFloat minutes / minutes_in_month
    in
        XMonths nearestMonth


moreThanTwoMonths :
    Int
    -> Date.Date
    -> Date.Date
    -> DistanceLocale
moreThanTwoMonths minutes d1 d2 =
    let
        months =
            Date.diff Month d1 d2
    in
        if months < 12 then
            -- 2 months up to 12 months
            upToOneYear minutes
        else
            -- 1 year up to max Date
            let
                monthsSinceStartOfYear =
                    months % 12

                years =
                    floor <| toFloat months / 12
            in
                if monthsSinceStartOfYear < 3 then
                    -- N years up to 1 years 3 months
                    AboutXYears years
                else if monthsSinceStartOfYear < 9 then
                    -- N years 3 months up to N years 9 months
                    OverXYears years
                else
                    -- N years 9 months up to N year 12 months
                    AlmostXYears <| years + 1


calculateDistance :
    Bool
    -> Date.Date
    -> Date.Date
    -> DistanceLocale
calculateDistance includeSeconds d1 d2 =
    let
        seconds =
            Date.diff Second d1 d2

        offset =
            (Date.offsetFromUtc d1) - (Date.offsetFromUtc d2)

        minutes =
            (round <| toFloat seconds / 60) - offset
    in
        if includeSeconds && minutes < 2 then
            upToOneMinute seconds
        else if minutes == 0 then
            LessThanXMinutes 1
        else if minutes < 2 then
            XMinutes minutes
        else if minutes < 45 then
            -- 2 mins up to 0.75 hrs
            XMinutes minutes
        else if minutes < 90 then
            -- 0.75 hrs up to 1.5 hrs
            AboutXHours 1
        else if minutes < minutes_in_day then
            -- 1.5 hrs up to 24 hrs
            upToOneDay minutes
        else if minutes < minutes_in_almost_two_days then
            -- 1 day up to 1.75 days
            XDays 1
        else if minutes < minutes_in_month then
            -- 1.75 days up to 30 days
            upToOneMonth minutes
        else if minutes < minutes_in_two_months then
            -- 1 month up to 2 months
            upToTwoMonths minutes
        else
            moreThanTwoMonths minutes d1 d2
