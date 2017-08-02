module Todo.Form
    exposing
        ( createAddTodoForm
        , createEditTodoForm
        , updateAddTodoForm
        , updateTodoForm
        )

import Data.TodoDoc exposing (..)
import Date
import Document
import Menu
import Time exposing (Time)
import Time.Format
import Todo.FormTypes exposing (..)
import Toolkit.Operators exposing (..)
import X.Record exposing (fieldLens, over, overM, set)


createEditTodoForm : EditTodoFormMode -> Time -> TodoDoc -> TodoForm
createEditTodoForm editMode now todo =
    let
        timeInMilli =
            Data.TodoDoc.getMaybeReminderTime todo ?= now + Time.hour

        form =
            { id = Document.getId todo
            , text = Data.TodoDoc.getText todo
            , contextId = Data.TodoDoc.getContextId todo
            , projectId = Data.TodoDoc.getProjectId todo
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
