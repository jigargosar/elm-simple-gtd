module Todo.Form exposing (..)

import Context
import Document
import Project
import Time exposing (Time)
import Time.Format
import Toolkit.Helpers exposing (..)
import Toolkit.Operators exposing (..)
import Ext.Function exposing (..)
import Ext.Function.Infix exposing (..)
import List.Extra as List
import Maybe.Extra as Maybe
import Todo


type alias TextFormModel =
    { id : Document.Id
    , todoText : Todo.Text
    }


type alias ReminderFormModel =
    { id : Document.Id
    , date : String
    , time : String
    , reminderMenuOpen : Bool
    }


type Form
    = TextForm TextFormModel
    | ReminderForm ReminderFormModel


type FormField
    = TextFormField TextFormFieldValue
    | ReminderFormField ReminderFormFieldValue


type TextFormFieldValue
    = Text String


type ReminderFormFieldValue
    = Date String
    | Time String
    | ReminderMenuOpen Bool


createReminderForm : Todo.Model -> Time -> Form
createReminderForm todo now =
    let
        timeInMilli =
            Todo.getDueAt todo ?= now + Time.hour
    in
        { id = Document.getId todo
        , date = (Time.Format.format "%Y-%m-%d") timeInMilli
        , time = (Time.Format.format "%H:%M") timeInMilli
        , reminderMenuOpen = False
        }
            |> ReminderForm


createTextForm : Todo.Model -> Project.Name -> Context.Name -> Time -> Form
createTextForm todo projectName contextName now =
    let
        timeInMilli =
            Todo.getDueAt todo ?= now + Time.hour
    in
        { id = Document.getId todo
        , todoText = Todo.getText todo
        }
            |> TextForm


set : FormField -> Form -> Form
set field form =
    case ( form, field ) of
        ( TextForm form, TextFormField field ) ->
            case field of
                Text value ->
                    TextForm { form | todoText = value }

        _ ->
            form
