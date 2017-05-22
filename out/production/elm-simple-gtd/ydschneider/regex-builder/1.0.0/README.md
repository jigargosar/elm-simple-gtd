# RegexBuilder

Compose a regex in Elm.

## Example

Let's say we want to parse a text file in [iCalendar](https://en.wikipedia.org/wiki/ICalendar)
format and read out all the start times.
Here's what a start time is encoded like:

- the keyword "DTSTART"
- possibly followed by some parameters
  - a parameter consists of a semicolon, its name, an '=', followed by its content
  - the content is a string. If it contains any of the seperators (';', ':'), it is enclosed in '"'
- a ':'
- the string denoting the actual start time. This is what we want.
- ended by "\r\n"

(For the sake of this example i'm assuming this is all taking place in one line of text.)

Here's what i came up with to do that:

```Elm
module ICalendar exposing (..)

import Regex exposing (Regex, regex)

startTimes : Regex
startTimes =
    regex  "DTSTART(?:;[^=]+=(?:[^:;]+|\"[^\"]+\"))*:([^\\r]+)\\r\\n"
```

It works. Or so I hope. If I messed up one sign it might not, and it surely is not nice to work with.
Here's what it looks like with RegexBuilder:

```Elm
module ICalendar exposing (..)

import RegexBuilder exposing (..)
import Regex exposing (Regex)

startTimes : Regex
startTimes =
    let
        paramContent =
            either
                [ char '"'
                    >> many (noneOf ['"'])
                    >> char '"'
                , many (noneOf [';', ':', '"'])
                ]

        parameter =
            char ';'
                >> many (noneOf ['='])
                >> char '='
                >> paramContent
    in
        exactly "DTSTART"
            >> maybe (many parameter)
            >> char ':'
            >> remember (many (noneOf ['\r']) )
            >> exactly "\r\n"
            |> toRegex
```

## Advantages

- easy to read
- some type safety
- no more double escaping, just Elm strings and chars

## Drawbacks

- early version, so use at your own risk!
- performance cost

Feedback and contributions are welcome!