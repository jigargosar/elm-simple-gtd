module X.Keyboard exposing (..)

import X.Decode exposing (traceDecoder)
import X.Html
import Html exposing (Attribute)
import Html.Events as Events
import Json.Decode as D exposing (Decoder)
import Json.Decode.Pipeline as D
import Keyboard.Extra as KX exposing (Key)
import Keyboard


onKeyUp : (KeyboardEvent -> msg) -> Attribute msg
onKeyUp onKeyMsg =
    Events.on "keyup" (D.map onKeyMsg (traceDecoder "kd" keyboardEventDecoder))


onKeyDown : (KeyboardEvent -> msg) -> Attribute msg
onKeyDown onKeyMsg =
    Events.on "keydown" (D.map onKeyMsg (traceDecoder "kd" keyboardEventDecoder))


onKeyDownPreventDefault : (KeyboardEvent -> msg) -> Attribute msg
onKeyDownPreventDefault onKeyMsg =
    X.Html.onPreventDefault "keydown" (D.map onKeyMsg (traceDecoder "kd" keyboardEventDecoder))


onKeyDownStopPropagation : (KeyboardEvent -> msg) -> Attribute msg
onKeyDownStopPropagation onKeyMsg =
    X.Html.onStopPropagation "keydown" (D.map onKeyMsg (traceDecoder "kd" keyboardEventDecoder))


targetKeyDecoder : Decoder Key
targetKeyDecoder =
    D.map KX.fromCode (D.field "keyCode" D.int)


keyboardEventDecoder : Decoder KeyboardEvent
keyboardEventDecoder =
    D.succeed KeyboardEvent
        |> D.custom targetKeyDecoder
        |> D.required "shiftKey" D.bool
        |> D.required "metaKey" D.bool
        |> D.required "ctrlKey" D.bool
        |> D.required "altKey" D.bool
        |> D.required "key" D.string


type alias KeyboardEvent =
    { key : Key
    , isShiftDown : Bool
    , isMetaDown : Bool
    , isControlDown : Bool
    , isAltDown : Bool
    , keyString : String
    }


isAnySoftKeyDown ke =
    ke.isShiftDown || ke.isMetaDown || ke.isControlDown || ke.isAltDown


isNoSoftKeyDown =
    isAnySoftKeyDown >> not


isOnlyShiftKeyDown ke =
    ke.isShiftDown
        && (not (ke.isMetaDown || ke.isControlDown || ke.isAltDown))


succeedIfDecodedKeyEquals key msg =
    KX.targetKey
        |> D.andThen
            (\actualKey ->
                {- let
                       _ =
                           X.Debug.log "actualKey, expectedKey" ( actualKey, key )
                   in
                -}
                if key == actualKey then
                    D.succeed msg
                else
                    D.fail "Not intrested"
            )


onEscape : msg -> Attribute msg
onEscape msg =
    Events.on "keyup" (succeedIfDecodedKeyEquals KX.Escape msg)


onEnter : msg -> Attribute msg
onEnter msg =
    Events.on "keyup" (succeedIfDecodedKeyEquals KX.Enter msg)


ups toMsg =
    Keyboard.ups (toMsg << KX.fromCode {- << X.Debug.log "global key code" -})


downs =
    KX.downs


init =
    KX.initialState


type alias Msg =
    KX.Msg


type alias Key =
    KX.Key


type alias State =
    KX.State


subscription : (Msg -> msg) -> Sub msg
subscription tagger =
    Sub.map tagger KX.subscriptions


update =
    KX.update


isShiftDown =
    KX.isPressed KX.Shift


isControlDown =
    KX.isPressed KX.Control


isAltDown =
    KX.isPressed KX.Alt


isMetaDown =
    KX.isPressed KX.Meta


isSuperDown =
    KX.isPressed KX.Super
