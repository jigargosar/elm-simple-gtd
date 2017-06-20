module RegexHelper exposing (..)

import RegexBuilder exposing (..)
import RegexBuilder.Extra exposing (..)
import Toolkit.Helpers exposing (..)
import Toolkit.Operators exposing (..)
import Ext.Function exposing (..)
import Ext.Function.Infix exposing (..)
import List.Extra as List
import Maybe.Extra as Maybe


linkUrl =
    urlPrefixPattern
        >> many noWhiteSpace
        |> RegexBuilder.toRegex


urlPrefixPattern =
    wordBoundary
        >> many (noWhiteSpace)
        >> exactly "://"
