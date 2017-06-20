module RegexHelper exposing (..)

import Regex exposing (HowMany(All))
import RegexBuilder exposing (..)
import RegexBuilder.Extra exposing (..)
import Toolkit.Helpers exposing (..)
import Toolkit.Operators exposing (..)
import Ext.Function exposing (..)
import Ext.Function.Infix exposing (..)
import List.Extra as List
import Maybe.Extra as Maybe


url =
    urlPrefixPattern
        >> many noWhiteSpace
        |> RegexBuilder.toRegex


urlPrefixPattern =
    wordBoundary
        >> many (noWhiteSpace)
        >> exactly "://"


stripUrlPrefix =
    let
        urlPrefix =
            urlPrefixPattern
                |> RegexBuilder.Extra.toRegex
                    { alignBeginning = True
                    , alignEnd = False
                    }
    in
        Regex.replace All urlPrefix (\_ -> "")
