module Todo.Form
    exposing
        ( createEditTodoForm
        , createAddTodoForm
        , updateAddTodoForm
        , updateEditTodoForm
        )

import Date
import Document.Types exposing (getDocId)
import Entity.Types exposing (Entity(TodoEntity))
import Menu
import Time exposing (Time)
import Time.Format
import Todo
import Todo.FormTypes exposing (..)
import Todo.Types exposing (TodoDoc, getTodoText)
import X.Record exposing (field, over, overM, set)
import Toolkit.Operators exposing (..)


createEditTodoForm : EditTodoFormMode -> Time -> TodoDoc -> EditTodoForm
createEditTodoForm etfMode now todo =
    let
        timeInMilli =
            Todo.getMaybeReminderTime todo ?= now + Time.hour

        form =
            { id = getDocId todo
            , text = getTodoText todo
            , todoId = getDocId todo
            , contextId = Todo.getContextId todo
            , projectId = Todo.getProjectId todo
            , menuState = Menu.initState
            , date = (Time.Format.format "%Y-%m-%d") timeInMilli
            , time = (Time.Format.format "%H:%M") timeInMilli
            , etfMode = etfMode
            , maybeComputedTime = Nothing
            , mode = TFM_Edit etfMode
            }
    in
        updateMaybeTime form


createAddTodoForm : AddTodoFormMode -> AddTodoForm
createAddTodoForm atfMode =
    { text = ""
    , menuState = Menu.initState
    , date = ""
    , time = ""
    , maybeComputedTime = Nothing
    , atfMode = atfMode
    , mode = TFM_Add atfMode
    }


updateAddTodoForm text form =
    { form | text = text }


text =
    field .text (\s b -> { b | text = s })


menuState =
    field .menuState (\s b -> { b | menuState = s })


date =
    field .date (\s b -> { b | date = s })


time =
    field .time (\s b -> { b | time = s })


maybeComputedTime =
    field .maybeComputedTime (\s b -> { b | maybeComputedTime = s })


updateEditTodoForm : EditTodoFormAction -> TodoFormCommon a -> TodoFormCommon a
updateEditTodoForm action =
    case action of
        SetTodoText value ->
            set text value

        SetTodoMenuState value ->
            set menuState value

        SetTodoReminderDate value ->
            set date value
                >> updateMaybeTime

        SetTodoReminderTime value ->
            set time value
                >> updateMaybeTime


updateMaybeTime : TodoFormCommon a -> TodoFormCommon a
updateMaybeTime =
    overM maybeComputedTime computeMaybeTime


computeMaybeTime : TodoFormCommon a -> Maybe Time
computeMaybeTime { date, time } =
    let
        dateTimeString =
            date ++ " " ++ time
    in
        Date.fromString (dateTimeString)
            !|> (Date.toTime >> Just)
            != Nothing
