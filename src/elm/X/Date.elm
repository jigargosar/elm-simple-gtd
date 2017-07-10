module X.Date exposing (..)

import Date exposing (Date)
import Date.Extra as Date
import Date.Format as Date


smartFormat : Date -> Date -> String
smartFormat refDate date =
    let
        formatTimeOfDay =
            Date.format "%l:%M%P"

        formatDateWithoutTime =
            Date.format "%e %b"

        formattedTime =
            formatTimeOfDay date |> String.trim

        formattedDate =
            formatDateWithoutTime date |> String.trim

        diffInDays =
            dayDiff refDate date
    in
        if diffInDays == 0 then
            formattedTime
        else if diffInDays == -1 then
            "Yesterday " ++ formattedTime
        else if diffInDays == 1 then
            "Tomorrow " ++ formattedTime
        else if diffInDays > 1 && diffInDays < 7 then
            (Date.format "%A " date) ++ formattedTime
        else
            formattedDate ++ " " ++ formattedTime


dayDiff refDate date =
    Date.diff Date.Day (Date.ceiling Date.Day refDate) (Date.ceiling Date.Day date)
