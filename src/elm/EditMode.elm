module EditMode exposing (..)

import Context
import Document
import Form
import LaunchBar.Form
import Project
import Todo
import Todo.NewForm
import Todo.GroupForm
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
    = NewTodo Todo.NewForm.Model
    | EditTodo Todo.Form.Model
    | EditContext EditContextForm
    | EditProject EditProjectForm
      -- overlay
    | EditTodoReminder Todo.ReminderForm.Model
    | EditTodoContext Todo.GroupForm.Model
    | EditTodoProject Todo.GroupForm.Model
    | LaunchBar LaunchBar.Form.Model
      -- different page !!
    | EditSyncSettings SyncForm
    | FirstVisit
    | None


none =
    None


firstVisit =
    FirstVisit


editContextMode model =
    EditContext { id = Document.getId model, name = Context.getName model }


editContextSetName name ecm =
    EditContext { ecm | name = name }


editProjectMode model =
    EditProject { id = Document.getId model, name = Project.getName model }


editProjectSetName name epm =
    EditProject { epm | name = name }
