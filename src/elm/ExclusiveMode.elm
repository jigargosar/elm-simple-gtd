module ExclusiveMode exposing (..)

import Entity.Types
import GroupDoc.EditForm
import LaunchBar.Form
import Menu
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
    | EditTodo Todo.Form.Model
    | EditContext EditContextForm
    | EditProject EditProjectForm
    | TodoMoreMenu Todo.Menu.Model
    | EditTodoReminder Todo.ReminderForm.Model
    | EditTodoContext Todo.GroupForm.Model
    | EditTodoProject Todo.GroupForm.Model
    | LaunchBar LaunchBar.Form.Model
    | MainMenu Menu.State
    | EditSyncSettings SyncForm
    | SignInOverlay
    | Setup Todo.NewForm.Model
    | None


none =
    None


signInOverlay =
    SignInOverlay


todoMoreMenu =
    Todo.Menu.init >> TodoMoreMenu


editProject =
    GroupDoc.EditForm.forProject >> EditProject


editProjectSetName =
    GroupDoc.EditForm.setName >>> EditProject


editContext =
    GroupDoc.EditForm.forContext >> EditContext


editContextSetName =
    GroupDoc.EditForm.setName >>> EditContext


editTodo =
    Todo.Form.create >> EditTodo


createEntityEditForm : Entity.Types.EntityType -> ExclusiveMode
createEntityEditForm entity =
    case entity of
        Entity.Types.GroupEntity g ->
            case g of
                Entity.Types.ContextEntity model ->
                    editContext model

                Entity.Types.ProjectEntity model ->
                    editProject model

        Entity.Types.TodoEntity model ->
            editTodo model
