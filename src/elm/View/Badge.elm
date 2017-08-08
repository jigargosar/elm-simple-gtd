module View.Badge exposing (..)

import Html exposing (Html, div, span, text)
import Html.Attributes exposing (class, style, tabindex)
import X.Function.Infix exposing (..)


badge : String -> Int -> Html msg
badge name count =
    div [ class "layout horizontal center" ]
        [ div [ class "font-nowrap" ] [ name |> text ]
        , div [ style [ "padding" => "0 0 1rem 0.1rem " ], class "text-secondary" ]
            [ " " ++ (count |> toString) ++ "" |> text ]
        ]


badgeStringSuffix : String -> String -> Html msg
badgeStringSuffix name suffix =
    div [ class "layout horizontal center" ]
        [ div [ class "font-nowrap" ] [ name |> text ]
        , div [ style [ "padding" => "0 0 1rem 0.1rem " ], class "text-secondary" ]
            [ " " ++ suffix ++ "" |> text ]
        ]
