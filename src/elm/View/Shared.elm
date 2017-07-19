module View.Shared exposing (..)

import Html exposing (Html, div, span, text)
import Html.Attributes exposing (class, style, tabindex)
import Mat
import X.Function.Infix exposing (..)
import Msg


badge : String -> Int -> Html msg
badge name count =
    div [ class "layout horizontal center" ]
        [ div [ class "font-nowrap" ] [ name |> text ]
        , div [ style [ "padding" => "0 0 1rem 0.1rem " ], class "text-secondary" ]
            [ " " ++ (count |> toString) ++ "" |> text ]
        ]


defaultOkCancelButtons =
    defaultOkCancelButtonsWith []


defaultOkCancelDeleteButtons deleteMsg =
    defaultOkCancelButtonsWith [ Mat.deleteButton deleteMsg ]


defaultOkCancelArchiveButtons isArchived archiveMsg =
    defaultOkCancelButtonsWith [ Mat.archiveButton isArchived archiveMsg ]


defaultOkCancelButtonsWith list =
    okCancelButtonsWith
        Msg.onSaveExclusiveModeForm
        Msg.revertExclusiveMode
        list


okCancelButtonsWith okMsg cancelMsg list =
    div [ class "layout horizontal-reverse" ]
        ([ Mat.okButton okMsg
         , Mat.cancelButton cancelMsg
         ]
            ++ list
        )
