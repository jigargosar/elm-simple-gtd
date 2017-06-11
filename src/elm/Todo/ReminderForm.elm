module Todo.ReminderForm exposing (..)

import Date
import Document
import Menu
import Time exposing (Time)
import Time.Format
import Toolkit.Helpers exposing (..)
import Toolkit.Operators exposing (..)
import Ext.Function exposing (..)
import Ext.Function.Infix exposing (..)
import List.Extra as List
import Maybe.Extra as Maybe
import Todo


type alias Model =
    { id : Document.Id
    , date : String
    , time : String
    , menuState : Menu.State
    }


type Action
    = SetDate String
    | SetTime String


create : Todo.Model -> Time.Time -> Model
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


set : Action -> Model -> Model
set action model =
    case action of
        SetDate value ->
            { model | date = value }

        SetTime value ->
            { model | time = value }


setMenuState menuState model =
    { model | menuState = menuState }


getMaybeTime : Model -> Maybe Time
getMaybeTime { id, date, time } =
    let
        dateTimeString =
            date ++ " " ++ time
    in
        Date.fromString (dateTimeString)
            !|> (Date.toTime >> Just)
            != Nothing
