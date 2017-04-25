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
    = Date String
    | Time String
    | ReminderMenuOpen Bool


create : Todo.Model -> Time.Time -> Model
create todo now =
    let
        timeInMilli =
            Todo.getDueAt todo ?= now + Time.hour
    in
        { id = Document.getId todo
        , date = (Time.Format.format "%Y-%m-%d") timeInMilli
        , time = (Time.Format.format "%H:%M") timeInMilli
        , reminderMenuOpen = False
        }
