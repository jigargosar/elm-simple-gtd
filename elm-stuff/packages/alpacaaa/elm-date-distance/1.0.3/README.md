# elm-date-distance

Distance between dates in words.
Example output:
- `5 minutes ago`
- `about 1 hour`
- `in 3 months`

Compatible with the core [Date type](http://package.elm-lang.org/packages/elm-lang/core/latest/Date).

## Installation

```sh
elm-package install alpacaaa/elm-date-distance
```

## Usage

```elm
import Date.Distance as Distance

-- Date.Extra is not required
-- you can create Date objects however you prefer
import Date.Extra as Date

date1 = Date.fromParts 2017 May 5 10 20 0 0
date2 = Date.fromParts 2017 May 7 10 20 0 0

Distance.inWords date1 date2 == "2 days"
```

You can also use a custom configuration
([Config docs](http://package.elm-lang.org/packages/alpacaaa/elm-date-distance/latest/Date-Distance-Types#Config)).

```elm
date1 = Date.fromParts 2017 May 7 10 20 0 0
date2 = Date.fromParts 2017 May 7 10 20 15 0

inWords = { Distance.defaultConfig | includeSeconds = True}
    |> Distance.inWordsWithConfig

inWords date1 date2 == "less than 20 seconds"
```

More examples are available in the [/tests](https://github.com/alpacaaa/elm-date-distance/tree/master/tests) folder.

For an in depth table of the results that this package can produce, check [Results.md](https://github.com/alpacaaa/elm-date-distance/blob/master/Results.md).

This package is heavily influenced by [date-fns](https://date-fns.org/docs/distanceInWords) `distanceInWords`.
