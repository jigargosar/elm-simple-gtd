module Todo.ReminderForm exposing (..)

import Date
import Document
import Document.Types exposing (DocId)
import Menu
import Menu.Types exposing (MenuState)
import Time exposing (Time)
import Time.Format
import Todo.Types exposing (TodoDoc)
import Toolkit.Operators exposing (..)
import Todo


type alias Model =
    { id : DocId
    , date : String
    , time : String
    , menuState : MenuState
    }


type Action
    = SetDate String
    | SetTime String
    | SetMenuState MenuState


create : TodoDoc -> Time.Time -> Model
create todo now =
    let
        timeInMilli =
            Todo.getMaybeReminderTime todo ?= now + Time.hour
    in
        { id = Document.getId todo
        , date = (Time.Format.format "%Y-%m-%d") timeInMilli
        , time = (Time.Format.format "%H:%M") timeInMilli
        , menuState = Menu.initState
        }


update : Action -> Model -> Model
update action model =
    case action of
        SetDate value ->
            { model | date = value }

        SetTime value ->
            { model | time = value }

        SetMenuState value ->
            { model | menuState = value }


getMaybeTime : Model -> Maybe Time
getMaybeTime { id, date, time } =
    let
        dateTimeString =
            date ++ " " ++ time
    in
        Date.fromString (dateTimeString)
            !|> (Date.toTime >> Just)
            != Nothing
