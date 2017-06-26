module ExclusiveMode exposing (..)

import ActionList

import GroupDoc.EditForm

import Entity

import LaunchBar.Form

import GroupDoc.EditForm

import Todo.Menu
import Todo.NewForm
import Todo.GroupForm



import X.Function.Infix exposing (..)



import Todo.Form
import Todo.ReminderForm


type alias EditContextForm =
    GroupDoc.EditForm.Model


type alias EditProjectForm =
    GroupDoc.EditForm.Model


type alias SyncForm =
    { uri : String }


type ExclusiveMode
    = NewTodo Todo.NewForm.Model
    | EditTask Todo.Form.Model
    | EditContext EditContextForm
    | EditProject EditProjectForm
      -- overlay
    | TaskMoreMenu Todo.Menu.Model
    | EditTodoReminder Todo.ReminderForm.Model
    | EditTodoContext Todo.GroupForm.Model
    | EditTodoProject Todo.GroupForm.Model
    | LaunchBar LaunchBar.Form.Model
    | ActionList ActionList.Model
      -- different page !!
    | EditSyncSettings SyncForm
    | SignInOverlay
    | Setup Todo.NewForm.Model
    | None


none =
    None


signInOverlay =
    SignInOverlay


initActionList =
    ActionList ActionList.init


taskMoreMenu =
    Todo.Menu.init >> TaskMoreMenu


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
