module KeyboardExtra exposing (..)

import Html exposing (Attribute)
import Html.Events as E
import Json.Decode as D exposing (Decoder)
import Keyboard
import Keyboard.Extra as Keyboard exposing (Key)
import Keyboard.Extra as KX


onKeyUp : (Key -> msg) -> Attribute msg
onKeyUp onKeyMsg =
    E.on "keyup" (D.map onKeyMsg Keyboard.targetKey)


succeedIfDecodedKeyEquals key msg =
    Keyboard.targetKey
        |> D.andThen
            (\actualKey ->
                if key == actualKey then
                    D.succeed msg
                else
                    D.fail "Not intrested"
            )


onEscape : msg -> Attribute msg
onEscape msg =
    E.on "keyup" (succeedIfDecodedKeyEquals Keyboard.Escape msg)


keyUps =
    KX.ups
