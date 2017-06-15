module ExclusiveMode exposing (..)

import ActionList
import Context
import Document
import Entity
import Form
import LaunchBar.Form
import Project
import Project.EditForm
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
    , entity : Entity.Entity
    }


type alias EntityForm =
    EditContextForm


type alias EditProjectForm =
    Project.EditForm.Model


type alias NewTodoModel =
    Todo.Text


type alias SyncForm =
    { uri : String }


type ExclusiveMode
    = NewTodo Todo.NewForm.Model
    | EditTodo Todo.Form.Model
    | EditContext EditContextForm
    | EditProject EditProjectForm
      -- overlay
    | EditTodoReminder Todo.ReminderForm.Model
    | EditTodoContext Todo.GroupForm.Model
    | EditTodoProject Todo.GroupForm.Model
    | LaunchBar LaunchBar.Form.Model
    | ActionList ActionList.Model
      -- different page !!
    | EditSyncSettings SyncForm
    | FirstVisit
    | None


none =
    None


firstVisit =
    FirstVisit


initActionList =
    ActionList ActionList.init


editContextMode context =
    EditContext
        { id = Document.getId context
        , name = Context.getName context
        , entity = Entity.ContextEntity context
        }


editContextSetName name ecm =
    EditContext { ecm | name = name }


editProjectMode =
    Project.EditForm.init >> EditProject


editProjectSetName =
    Project.EditForm.setName >>> EditProject
