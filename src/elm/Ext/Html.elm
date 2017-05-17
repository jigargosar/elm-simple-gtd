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


targetAncestorIds : Decoder (List Dom.Id)
targetAncestorIds =
    targetAncestorIdsHelp (DOM.target domIdDecoder) []
        |> D.map (reject String.isEmpty)


targetAncestorIdsHelp : Decoder Dom.Id -> List Dom.Id -> Decoder (List Dom.Id)
targetAncestorIdsHelp target ids =
    D.oneOf
        [ target
            |> D.andThen
                (\domId ->
                    let
                        parentIndex =
                            (List.length ids) + 1
                    in
                        targetAncestorIdsHelp
                            (nthParent parentIndex domIdDecoder)
                            (domId :: ids)
                )
        , D.succeed ids
        ]


nthParent : Int -> Decoder a -> Decoder a
nthParent count decoder =
    List.foldl (\_ acc -> DOM.parentElement acc) decoder (List.range 0 count)
        |> DOM.target


onClickAllParentIds toMsg =
    Html.Events.on "click" (D.map toMsg targetAncestorIds)


targetHasAncestorWithId : Dom.Id -> msg -> Decoder msg
targetHasAncestorWithId ancestorId msg =
    targetHasAncestorWithIdHelp ancestorId msg (DOM.target domIdDecoder) []


targetHasAncestorWithIdHelp : Dom.Id -> msg -> Decoder Dom.Id -> List Dom.Id -> Decoder msg
targetHasAncestorWithIdHelp ancestorId msg target ids =
    target
        |> D.andThen
            (\domId ->
                if domId == ancestorId then
                    D.succeed msg
                else
                    let
                        parentIndex =
                            (List.length ids) + 1
                    in
                        targetHasAncestorWithIdHelp
                            ancestorId
                            msg
                            (nthParent parentIndex domIdDecoder)
                            (domId :: ids)
            )


onClickContainingAncestorId ancestorId toMsg =
    Html.Events.on "click" (D.map toMsg targetAncestorIds)
