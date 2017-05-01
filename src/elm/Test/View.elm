module Test.View exposing (..)

import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Html.Events.Extra exposing (onClickStopPropagation)
import Toolkit.Helpers exposing (..)
import Toolkit.Operators exposing (..)
import Ext.Function exposing (..)
import Ext.Function.Infix exposing (..)
import List.Extra as List
import Maybe.Extra as Maybe
import String.Extra


createItems =
    List.range 0 10 .|> createItem


createItem idx =
    li [ tabindex 1 ] [ idx |> toString >> String.append "item no: " >> text ]


init =
    ul [] createItems
