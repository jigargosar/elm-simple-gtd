module RegexHelper exposing (..)

import Regex exposing (HowMany(All))


url =
    urlPrefixRegexString ++ "\\S+" |> Regex.regex


urlPrefixRegexString =
    "[A-Za-z]+://"


stripUrlPrefix =
    let
        urlPrefix =
            Regex.regex ("^" ++ urlPrefixRegexString)
    in
        Regex.replace All urlPrefix (\_ -> "")
