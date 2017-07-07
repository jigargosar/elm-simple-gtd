module X.Decode exposing (..)

import Json.Decode exposing (..)
import X.Debug


traceDecoder : String -> Decoder msg -> Decoder msg
traceDecoder message decoder =
    value
        |> andThen
            (\value ->
                case decodeValue decoder value of
                    Ok decoded ->
                        succeed decoded

                    Err err ->
                        fail <| X.Debug.log message <| err
            )
