module Todo.Form
    exposing
        ( createAddTodoForm
        , createEditTodoForm
        , updateAddTodoForm
        , updateTodoForm
        )

import Date
import Document
import Menu
import Time exposing (Time)
import Time.Format
import Todo
import Todo.FormTypes exposing (..)
import Toolkit.Operators exposing (..)
import Types.Todo exposing (..)
import X.Record exposing (fieldLens, over, overM, set)


createEditTodoForm : EditTodoFormMode -> Time -> TodoDoc -> TodoForm
createEditTodoForm editMode now todo =
    let
        timeInMilli =
            Todo.getMaybeReminderTime todo ?= now + Time.hour

        form =
            { id = Document.getId todo
            , text = Todo.getText todo
            , contextId = Todo.getContextId todo
            , projectId = Todo.getProjectId todo
            , menuState = Menu.initState
            , date = Time.Format.format "%Y-%m-%d" timeInMilli
            , time = Time.Format.format "%H:%M" timeInMilli
            , maybeComputedTime = Nothing
            , mode = TFM_Edit editMode
            }
    in
    updateMaybeTime form


createAddTodoForm : AddTodoFormMode -> TodoForm
createAddTodoForm addMode =
    { id = ""
    , contextId = ""
    , projectId = ""
    , text = ""
    , menuState = Menu.initState
    , date = ""
    , time = ""
    , maybeComputedTime = Nothing
    , mode = TFM_Add addMode
    }


updateAddTodoForm text form =
    { form | text = text }


text =
    fieldLens .text (\s b -> { b | text = s })


menuState =
    fieldLens .menuState (\s b -> { b | menuState = s })


date =
    fieldLens .date (\s b -> { b | date = s })


time =
    fieldLens .time (\s b -> { b | time = s })


maybeComputedTime =
    fieldLens .maybeComputedTime (\s b -> { b | maybeComputedTime = s })


updateTodoForm : TodoFormAction -> TodoForm -> TodoForm
updateTodoForm action =
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


updateMaybeTime : TodoForm -> TodoForm
updateMaybeTime =
    overM maybeComputedTime computeMaybeTime


computeMaybeTime : TodoForm -> Maybe Time
computeMaybeTime { date, time } =
    let
        dateTimeString =
            date ++ " " ++ time
    in
    Date.fromString dateTimeString
        !|> (Date.toTime >> Just)
        != Nothing
