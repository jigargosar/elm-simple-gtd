module Ext.Html exposing (..)

import DOM
import Dom
import Html.Attributes exposing (..)
import Html.Attributes.Extra exposing (..)
import Toolkit.Helpers exposing (..)
import Toolkit.Operators exposing (..)
import Ext.Function exposing (..)
import Ext.Function.Infix exposing (..)
import List.Extra as List
import Maybe.Extra as Maybe
import Json.Decode as D exposing (Decoder)
import Json.Decode.Pipeline as D
import Json.Encode as E


_ =
    1


attr =
    attribute


prop =
    stringProperty


intProp =
    intProperty


boolProp =
    boolProperty


floatProp =
    floatProperty


domIdDecoder : Decoder Dom.Id
domIdDecoder =
    D.field "id" D.string


targetParentIds : Decoder (List Dom.Id)
targetParentIds =
    domIdDecoder
        |> DOM.parentElement
        |> DOM.parentElement
        |> DOM.parentElement
        |> DOM.parentElement
        |> DOM.parentElement
        |> DOM.parentElement
        |> DOM.parentElement
        |> DOM.parentElement
        |> DOM.target
        |> D.map List.singleton


targetParentIds2 : Decoder (List Dom.Id)
targetParentIds2 =
    recursion (D.field "target") []


recursion : (Decoder Dom.Id -> Decoder Dom.Id) -> List Dom.Id -> Decoder (List Dom.Id)
recursion target ids =
    D.oneOf
        [ target domIdDecoder
            |> D.andThen (\domId -> recursion (D.field "parentElement") (domId :: ids))
        , D.succeed ids
        ]
