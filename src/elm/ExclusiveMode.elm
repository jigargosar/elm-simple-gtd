module ExclusiveMode exposing (..)

import ActionList
import Context
import GroupDoc.EditForm
import Document
import Entity
import Form
import LaunchBar.Form
import Project
import GroupDoc.EditForm
import Todo
import Todo.Menu
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
    GroupDoc.EditForm.Model


type alias EditProjectForm =
    GroupDoc.EditForm.Model


type alias NewTodoModel =
    Todo.Text


type alias SyncForm =
    { uri : String }


type ExclusiveMode
    = NewTodo Todo.NewForm.Model
    | EditTask Todo.Form.Model
    | EditContext EditContextForm
    | EditProject EditProjectForm
      -- overlay
    | TodoMoreMenu Todo.Menu.Model
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


editProject =
    GroupDoc.EditForm.forProject >> EditProject


editProjectSetName =
    GroupDoc.EditForm.setName >>> EditProject


editContext =
    GroupDoc.EditForm.forContext >> EditContext


editContextSetName =
    GroupDoc.EditForm.setName >>> EditContext


editTask =
    Todo.Form.create >> EditTask


createEntityEditForm : Entity.Entity -> ExclusiveMode
createEntityEditForm entity =
    case entity of
        Entity.Group g ->
            case g of
                Entity.Context model ->
                    editContext model

                Entity.Project model ->
                    editProject model

        Entity.Task model ->
            editTask model
