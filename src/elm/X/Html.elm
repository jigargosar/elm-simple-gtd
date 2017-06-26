module X.Html exposing (..)

import DOM
import Dom
import Html exposing (Attribute)
import Html.Attributes exposing (..)
import Html.Events exposing (onWithOptions)

import Toolkit.Operators exposing (..)

import X.Function.Infix exposing (..)
import List.Extra as List
import Maybe.Extra as Maybe
import Json.Decode as D exposing (Decoder)

import Json.Encode as E



stopPropagation =
    { stopPropagation = True
    , preventDefault = False
    }


preventDefault =
    { stopPropagation = False
    , preventDefault = True
    }


stopAll =
    { stopPropagation = True
    , preventDefault = True
    }


onStopPropagation eventName =
    onWithOptions eventName stopPropagation


onPreventDefault eventName =
    onWithOptions eventName preventDefault


onStopAll eventName =
    onWithOptions eventName stopAll


onClickStopPropagation =
    D.succeed >> onStopPropagation "click"


onClickStopAll =
    D.succeed >> onStopAll "click"


onMouseDownStopPropagation =
    D.succeed >> onStopPropagation "mousedown"


attr =
    attribute


prop =
    stringProperty


stringProperty : String -> String -> Attribute msg
stringProperty name value =
    E.string value |> property name


boolProp =
    boolProperty


boolProperty : String -> Bool -> Attribute msg
boolProperty name value =
    E.bool value |> property name


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


onClickTargetPathHavingIds =
    targetPathHavingIds >>> Html.Events.on "click"


targetPathHavingIds domIds toMsg =
    let
        failFn =
            (\_ -> D.fail ("domIds not found in event target path: " ++ (toString domIds)))

        successFn =
            (\_ -> D.succeed toMsg)
    in
        (targetAncestorIds
            |> D.andThen
                (List.find (List.member # domIds) >> Maybe.unpack successFn failFn)
        )
