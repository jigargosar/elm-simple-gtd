module Todo.ReminderForm exposing (..)

import Date
import Document
import Menu
import Time exposing (Time)
import Time.Format
import Todo.Types exposing (TodoDoc)
import Toolkit.Operators exposing (..)
import Todo
import Todo.Form exposing (EditTodoReminderFormAction(..), EditTodoReminderForm)


create : TodoDoc -> Time.Time -> EditTodoReminderForm
create todo now =
    let
        timeInMilli =
            Todo.getMaybeReminderTime todo ?= now + Time.hour
    in
        { id = Document.getId todo
        , date = (Time.Format.format "%Y-%m-%d") timeInMilli
        , time = (Time.Format.format "%H:%M") timeInMilli
        }


update : EditTodoReminderFormAction -> EditTodoReminderForm -> EditTodoReminderForm
update action model =
    case action of
        SetTodoReminderDate value ->
            { model | date = value }

        SetTodoReminderTime value ->
            { model | time = value }


getMaybeTime : EditTodoReminderForm -> Maybe Time
getMaybeTime { id, date, time } =
    let
        dateTimeString =
            date ++ " " ++ time
    in
        Date.fromString (dateTimeString)
            !|> (Date.toTime >> Just)
            != Nothing
