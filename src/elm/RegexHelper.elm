module RegexHelper exposing (..)

import Regex exposing (HowMany(All))
import Toolkit.Helpers exposing (..)
import Toolkit.Operators exposing (..)
import Ext.Function exposing (..)
import Ext.Function.Infix exposing (..)
import List.Extra as List
import Maybe.Extra as Maybe


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
