module Ext.Decode exposing (..)

import Json.Decode exposing (..)
import Json.Decode.Pipeline exposing (..)


traceDecoder : String -> Decoder msg -> Decoder msg
traceDecoder message decoder =
    value
        |> andThen
            (\value ->
                case decodeValue decoder value of
                    Ok decoded ->
                        succeed decoded

                    Err err ->
                        fail <| Debug.log message <| err
            )
