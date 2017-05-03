module Todo.ReminderForm exposing (..)

import Document
import Time
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
    , reminderMenuOpen : Bool
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
        , reminderMenuOpen = False
        }


set : Action -> Model -> Model
set action model =
    case action of
        SetDate value ->
            { model | date = value }

        SetTime value ->
            { model | time = value }
