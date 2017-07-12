module Todo.Form exposing (..)

import Date
import Document
import Document.Types exposing (getDocId)
import Entity.Types exposing (Entity(TodoEntity))
import Menu
import Time exposing (Time)
import Time.Format
import Todo
import Todo.FormTypes exposing (..)
import Todo.Types exposing (TodoDoc, getTodoText)
import X.Record exposing (field, set)
import Toolkit.Operators exposing (..)
import Toolkit.Helpers exposing (..)


create : Time -> TodoDoc -> TodoEditForm
create now todo =
    let
        timeInMilli =
            Todo.getMaybeReminderTime todo ?= now + Time.hour
    in
        { id = getDocId todo
        , name = getTodoText todo
        , entity = TodoEntity todo
        , todoId = getDocId todo
        , contextId = Todo.getContextId todo
        , projectId = Todo.getProjectId todo
        , menuState = Menu.initState
        , date = (Time.Format.format "%Y-%m-%d") timeInMilli
        , time = (Time.Format.format "%H:%M") timeInMilli
        }


createNewTodoForm : Entity -> Todo.Text -> AddTodoForm
createNewTodoForm referenceEntity text =
    { text = text, referenceEntity = referenceEntity }


setNewTodoFormText text form =
    { form | text = text }


name =
    field .name (\s b -> { b | name = s })


menuState =
    field .menuState (\s b -> { b | menuState = s })


date =
    field .date (\s b -> { b | date = s })


time =
    field .time (\s b -> { b | time = s })


update : EditTodoFormAction -> TodoEditForm -> TodoEditForm
update action =
    case action of
        SetTodoText value ->
            set name value

        SetTodoMenuState value ->
            set menuState value

        SetTodoReminderDate value ->
            set date value

        SetTodoReminderTime value ->
            set time value


getMaybeTime : TodoEditForm -> Maybe Time
getMaybeTime { id, date, time } =
    let
        dateTimeString =
            date ++ " " ++ time
    in
        Date.fromString (dateTimeString)
            !|> (Date.toTime >> Just)
            != Nothing
