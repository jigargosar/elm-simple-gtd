module ExclusiveMode exposing (..)

import ActionList
import Context
import Context.EditForm
import Document
import Entity
import Form
import LaunchBar.Form
import Project
import GroupDoc.EditForm
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
    Context.EditForm.Model


type alias EntityForm =
    EditContextForm


type alias EditProjectForm =
    GroupDoc.EditForm.Model


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


editProjectMode =
    GroupDoc.EditForm.init Entity.ProjectEntity >> EditProject


editProjectSetName =
    GroupDoc.EditForm.setName >>> EditProject


editContextMode =
    Context.EditForm.init >> EditContext


editContextSetName =
    Context.EditForm.setName >>> EditContext
