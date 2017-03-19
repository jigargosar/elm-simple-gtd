module KeyboardExtra exposing (..)

import Html exposing (Attribute)
import Html.Events as Events
import Json.Decode as D exposing (Decoder)
import Keyboard
import Keyboard.Extra as Keyboard exposing (Key)
import Keyboard.Extra as KX


onKeyUp : (Key -> msg) -> Attribute msg
onKeyUp onKeyMsg =
    Events.on "keyup" (D.map onKeyMsg Keyboard.targetKey)


succeedIfDecodedKeyEquals key msg =
    Keyboard.targetKey
        |> D.andThen
            (\actualKey ->
                let
                    _ =
                        Debug.log "actualKey, expectedKey" ( actualKey, key )
                in
                    if key == actualKey then
                        D.succeed msg
                    else
                        D.fail "Not intrested"
            )


onEscape : msg -> Attribute msg
onEscape msg =
    Events.on "keyup" (succeedIfDecodedKeyEquals Keyboard.Escape msg)


onEnter : msg -> Attribute msg
onEnter msg =
    Events.on "keyup" (succeedIfDecodedKeyEquals Keyboard.Enter msg)


keyUps =
    KX.ups
