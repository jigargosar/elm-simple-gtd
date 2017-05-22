module Date.Distance.Types
    exposing
        ( Locale
        , Config
        , DistanceLocale(..)
        )

{-|
@docs Config
@docs Locale
@docs DistanceLocale
-}


{-| Data type used by localization functions
to produce a string.
-}
type DistanceLocale
    = LessThanXSeconds Int
    | HalfAMinute
    | LessThanXMinutes Int
    | XMinutes Int
    | AboutXHours Int
    | XDays Int
    | AboutXMonths Int
    | XMonths Int
    | AboutXYears Int
    | OverXYears Int
    | AlmostXYears Int


{-| A localization function takes two arguments:
* `Order` – determines if the first date passed to `inWords`
is after the second date (useful for relative distances)

* `DistanceLocale` – distance between the two dates
-}
type alias Locale =
    Order -> DistanceLocale -> String


{-| To be used with `inWordsWithConfig`.

* `locale` – localization function (see `I18n.En`)
* `includeSeconds` – get more precise results for distances under a minute
-}
type alias Config =
    { locale : Locale
    , includeSeconds : Bool
    }
