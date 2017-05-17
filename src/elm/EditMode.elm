module EditMode exposing (..)

import Context
import Document
import Form
import Project
import Todo
import Todo.NewForm
import Toolkit.Helpers exposing (..)
import Toolkit.Operators exposing (..)
import Ext.Function exposing (..)
import Ext.Function.Infix exposing (..)
import List.Extra as List
import Maybe.Extra as Maybe
import Time exposing (Time)
import Time.Format
import Todo.Form
import Todo.ReminderForm


type alias EditContextForm =
    { id : Document.Id
    , name : Context.Name
    }


type alias EntityForm =
    EditContextForm


type alias EditProjectForm =
    { id : Document.Id
    , name : Project.Name
    }


type alias NewTodoModel =
    Todo.Text


type alias SyncForm =
    { uri : String }


type EditMode
    = NewTodo Form.Model
    | EditTodo Todo.Form.Model
    | EditTodoReminder Todo.ReminderForm.Model
    | EditTodoContext Todo.Model
    | EditTodoProject Todo.Model
    | EditContext EditContextForm
    | EditProject EditProjectForm
    | EditSyncSettings SyncForm
    | None


none =
    None


editContextMode model =
    EditContext { id = Document.getId model, name = Context.getName model }


editContextSetName name ecm =
    EditContext { ecm | name = name }


editProjectMode model =
    EditProject { id = Document.getId model, name = Project.getName model }


editProjectSetName name epm =
    EditProject { epm | name = name }


getMaybeEditTodoModel model =
    case model of
        EditTodo model ->
            Just model

        _ ->
            Nothing


getNewTodoModel model =
    case model of
        NewTodo model ->
            Just model

        _ ->
            Nothing
