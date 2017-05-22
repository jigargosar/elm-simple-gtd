module Date.Distance.I18n.En
    exposing
        ( LocaleConfig
        , locale
        )

{-| English locale. Used by default.
@docs LocaleConfig
@docs locale
-}

import String
import Date.Distance.Types exposing (Locale, DistanceLocale(..))
import Date.Extra as Date exposing (Interval(..))


{-| Configure the localization function.
* `addSuffix` – turns `2 days` into `2 days ago` or `in 2 days`
-}
type alias LocaleConfig =
    { addSuffix : Bool
    }


{-| Configure the English locale.

    locale = I18n.En.locale { addSuffix = True }
    inWords = { defaultConfig | locale = locale }
      |> inWordsWithConfig
-}
locale : LocaleConfig -> Locale
locale { addSuffix } order distance =
    let
        result =
            locale_ distance
    in
        if addSuffix then
            if order == LT then
                "in " ++ result
            else
                result ++ " ago"
        else
            result


locale_ : DistanceLocale -> String
locale_ distance =
    case distance of
        LessThanXSeconds i ->
            circa "less than" Second i

        HalfAMinute ->
            "half a minute"

        LessThanXMinutes i ->
            circa "less than" Minute i

        XMinutes i ->
            exact Minute i

        AboutXHours i ->
            circa "about" Hour i

        XDays i ->
            exact Day i

        AboutXMonths i ->
            circa "about" Month i

        XMonths i ->
            exact Month i

        AboutXYears i ->
            circa "about" Year i

        OverXYears i ->
            circa "over" Year i

        AlmostXYears i ->
            circa "almost" Year i


formatInterval : Interval -> String
formatInterval =
    String.toLower << toString


singular : Interval -> String
singular interval =
    case interval of
        Minute ->
            "a " ++ formatInterval interval

        _ ->
            "1 " ++ formatInterval interval


circa : String -> Interval -> Int -> String
circa prefix interval i =
    case i of
        1 ->
            prefix ++ " " ++ singular interval

        _ ->
            prefix ++ " " ++ toString i ++ " " ++ formatInterval interval ++ "s"


exact : Interval -> Int -> String
exact interval i =
    case i of
        1 ->
            "1 " ++ formatInterval interval

        _ ->
            toString i ++ " " ++ formatInterval interval ++ "s"
