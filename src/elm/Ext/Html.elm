module Ext.Html exposing (..)

import DOM
import Dom
import Html.Attributes exposing (..)
import Html.Attributes.Extra exposing (..)
import Html.Events
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



--targetParentIds : Decoder (List Dom.Id)
--targetParentIds =
--    domIdDecoder
--        |> DOM.parentElement
--        |> DOM.parentElement
--        |> DOM.parentElement
--        |> DOM.parentElement
--        |> DOM.parentElement
--        |> DOM.parentElement
--        |> DOM.parentElement
--        |> DOM.parentElement
--        |> DOM.target
--        |> D.map List.singleton
--


targetParentIds : Decoder (List Dom.Id)
targetParentIds =
    targetParentIdsHelp (DOM.target domIdDecoder) []
        |> D.map (reject String.isEmpty)


targetParentIdsHelp : Decoder Dom.Id -> List Dom.Id -> Decoder (List Dom.Id)
targetParentIdsHelp target ids =
    D.oneOf
        [ target
            |> D.andThen
                (\domId ->
                    let
                        newDomIds =
                            (domId :: ids)

                        parentElementCount =
                            (List.length ids) + 1
                    in
                        targetParentIdsHelp (recursivelyApplyParentElement parentElementCount) newDomIds
                )
        , D.succeed ids
        ]


recursivelyApplyParentElement : Int -> Decoder Dom.Id
recursivelyApplyParentElement count =
    List.foldl (\_ acc -> DOM.parentElement acc) domIdDecoder (List.range 0 count)
        |> DOM.target


onClickAllParentIds toMsg =
    Html.Events.on "click" (D.map toMsg targetParentIds)


onClickContainingAncestorId ancestorId toMsg =
    Html.Events.on "click" (D.map toMsg targetParentIds)
