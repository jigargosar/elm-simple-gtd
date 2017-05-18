module Ext.Html exposing (..)

import DOM
import Dom
import Html
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


targetAncestorIds : Decoder (List Dom.Id)
targetAncestorIds =
    targetAncestorIdsHelp (DOM.target domIdDecoder) []


targetAncestorIdsHelp : Decoder Dom.Id -> List Dom.Id -> Decoder (List Dom.Id)
targetAncestorIdsHelp target ids =
    D.oneOf
        [ target
            |> D.andThen
                (\domId ->
                    let
                        parentIndex =
                            (List.length ids)
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


onClickPathIds toMsg =
    Html.Events.on "click" (D.map toMsg targetAncestorIds)


onClickWithTargetPathIds domIds toMsg =
    let
        failFn =
            (\_ -> D.fail ("domIds not found in event target path: " ++ (toString domIds)))

        successFn =
            (\_ -> D.succeed toMsg)
    in
        Html.Events.on "click"
            (targetAncestorIds
                |> D.andThen
                    (List.find (List.member # domIds) >> Maybe.unpack failFn successFn)
            )


targetHasAncestorWithIds : List Dom.Id -> msg -> Decoder msg
targetHasAncestorWithIds =
    targetHasAncestorWithIdsHelp domIdDecoder 0


targetHasAncestorWithIdsHelp : Decoder Dom.Id -> Int -> List Dom.Id -> msg -> Decoder msg
targetHasAncestorWithIdsHelp decoder count ancestorIds msg =
    decoder
        |> D.andThen
            (\domId ->
                if List.member domId ancestorIds then
                    D.succeed msg
                else
                    targetHasAncestorWithIdsHelp
                        (nthParent count domIdDecoder)
                        (count + 1)
                        ancestorIds
                        msg
            )


onClickContainingAncestorId : Dom.Id -> msg -> Html.Attribute msg
onClickContainingAncestorId =
    List.singleton >> onClickContainingAncestorIds


onClickContainingAncestorIds : List Dom.Id -> msg -> Html.Attribute msg
onClickContainingAncestorIds =
    targetHasAncestorWithIds >>> Html.Events.on "click"
