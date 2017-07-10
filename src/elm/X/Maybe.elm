module X.Maybe exposing (..)


toList maybe =
    case maybe of
        Just just ->
            [ just ]

        Nothing ->
            []
