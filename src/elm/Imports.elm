port module Imports exposing (..)

import Regex
import RegexHelper
import Return exposing (command, return, singleton)
import Toolkit.Helpers exposing (..)
import Toolkit.Operators exposing (..)
import X.Function exposing (..)
import X.Function.Infix exposing (..)
import List.Extra as List
import Maybe.Extra as Maybe


port output : String -> Cmd msg


type alias Model =
    ()


type Msg
    = ParseImports


init =
    singleton ()
        |> update ParseImports


importRegex =
    --    Regex.regex "(?:^|\\n)import\\s([\\w\\.]+)(?:\\s+as\\s+(\\w+))?(?:\\s+exposing\\s*\\(((?:\\s*(?:\\w+|\\(.+\\)|\\w+\\(.+\\))\\s*,)*)\\s*((?:\\.\\.|\\w+|\\(.+\\)|\\w+\\(.+\\)))\\s*\\))?"
    Regex.regex "(?:^|\\n)import\\s([\\w\\.]+)"


update msg =
    case msg of
        ParseImports ->
            let
                matches =
                    Regex.find Regex.All importRegex """import Jxs as ex exposing (.., a, b)
import Foo.BAr as ex exposing (a,a,a,a,a, b)"""
                        |> Debug.log "matches"
            in
                matches
                    .|> (.submatches >> List.head >> Maybe.join)
                    |> List.filterMap identity
                    .|> output
                    |> Cmd.batch
                    |> command


subscriptions model =
    Sub.none


main : Program Never Model Msg
main =
    Platform.program
        { init = init
        , update = (\msg -> singleton >> update msg)
        , subscriptions = subscriptions
        }
