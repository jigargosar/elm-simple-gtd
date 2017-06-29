module View.Shared exposing (..)

import Html exposing (Html, div, span, text)
import Html.Attributes exposing (class, style, tabindex)
import Html.Events exposing (onClick)
import Model
import Model
import Polymer.Paper as Paper exposing (badge)
import X.Function.Infix exposing (..)
import Model exposing (Model)


defaultBadge : { x | name : String, count : Int } -> Html msg
defaultBadge vm =
    div [ class "layout horizontal center" ]
        [ div [ class "font-nowrap" ] [ vm.name |> text ]
        , div [ style [ "padding" => "0 0 1rem 0.1rem " ], class "text-secondary" ]
            [ " " ++ (vm.count |> toString) ++ "" |> text ]
        ]


badge : String -> Int -> Html msg
badge name count =
    div [ class "layout horizontal center" ]
        [ div [ class "font-nowrap" ] [ name |> text ]
        , div [ style [ "padding" => "0 0 1rem 0.1rem " ], class "text-secondary" ]
            [ " " ++ (count |> toString) ++ "" |> text ]
        ]


defaultOkCancelButtons =
    defaultOkCancelButtonsWith []


defaultOkCancelButtonsWith list =
    okCancelButtonsWith Model.OnSaveCurrentForm Model.OnDeactivateEditingMode list


defaultOkCancelDeleteButtons deleteMsg =
    defaultOkCancelButtonsWith [ deleteButton deleteMsg ]


defaultOkCancelArchiveButtons isArchived archiveMsg =
    defaultOkCancelButtonsWith [ archiveButton isArchived archiveMsg ]


okCancelButtonsWith okMsg cancelMsg list =
    div [ class "layout horizontal-reverse" ]
        ([ okButton okMsg
         , cancelButton cancelMsg
         ]
            ++ list
        )


okButton msg =
    Paper.button [ onClick msg ] [ text "Ok" ]


cancelButton msg =
    Paper.button [ onClick msg ] [ text "Cancel" ]


deleteButton msg =
    Paper.button [ onClick msg ] [ text "Delete" ]


archiveButton isArchived msg =
    Paper.button [ onClick msg ]
        [ text
            (if isArchived then
                "Unarchive"
             else
                "Archive"
            )
        ]
