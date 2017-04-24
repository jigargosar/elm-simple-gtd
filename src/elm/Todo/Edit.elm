module Todo.Edit exposing (..)

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


type alias Form =
    { id : Document.Id
    , todoText : Todo.Text
    , projectName : Project.Name
    , contextName : Context.Name
    , date : String
    , time : String
    , reminderMenuOpen : Bool
    }


type Field
    = ProjectName String
    | ContextName String
    | Text String
    | Date String
    | Time String
    | ReminderMenuOpen Bool


create : Todo.Model -> Project.Name -> Context.Name -> Time -> Form
create todo projectName contextName now =
    let
        timeInMilli =
            Todo.getDueAt todo ?= now + Time.hour
    in
        { id = Document.getId todo
        , todoText = Todo.getText todo
        , projectName = projectName
        , contextName = contextName
        , date = (Time.Format.format "%Y-%m-%d") timeInMilli
        , time = (Time.Format.format "%H:%M") timeInMilli
        , reminderMenuOpen = "false"
        }


set : Field -> Form -> Form
set field model =
    case field of
        ProjectName value ->
            { model | projectName = value }

        ContextName value ->
            { model | contextName = value }

        Text value ->
            { model | todoText = value }

        Date value ->
            { model | date = value }

        Time value ->
            { model | time = value }

        ReminderMenuOpen value ->
            { model | reminderMenuOpen = value }
