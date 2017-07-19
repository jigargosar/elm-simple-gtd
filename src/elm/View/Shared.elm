module View.Shared exposing (..)

import Html exposing (Html, div, span, text)
import Html.Attributes exposing (class, style, tabindex)
import Mat
import X.Function.Infix exposing (..)
import Msg


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
