module View.Shared exposing (..)

import Html exposing (Html, div, span, text)
import Html.Attributes exposing (class, style, tabindex)
import Html.Events exposing (onClick)
import Mat
import Model
import Model
import X.Function.Infix exposing (..)
import Model exposing (Model)


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
    Mat.buttonFlat "Ok" [ onClick msg ]


cancelButton msg =
    Mat.buttonFlat "Cancel" [ onClick msg ]


deleteButton msg =
    Mat.buttonFlat "Delete" [ onClick msg ]


archiveButton isArchived msg =
    Mat.buttonFlat
        (if isArchived then
            "Unarchive"
         else
            "Archive"
        )
        [ onClick msg ]
