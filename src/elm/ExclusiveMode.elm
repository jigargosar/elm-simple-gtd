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
    = XMNewTodo Todo.NewForm.Model
    | XMEditTodo Todo.Form.Model
    | XMEditContext EditContextForm
    | XMEditProject EditProjectForm
    | XMTodoMoreMenu Todo.Menu.Model
    | XMEditTodoReminder Todo.ReminderForm.Model
    | XMEditTodoContext Todo.GroupForm.Model
    | XMEditTodoProject Todo.GroupForm.Model
    | XMLaunchBar LaunchBar.Form.Model
    | XMMainMenu Menu.State
    | XMEditSyncSettings SyncForm
    | XMSignInOverlay
    | XMSetup Todo.NewForm.Model
    | XMNone


none =
    XMNone


signInOverlay =
    XMSignInOverlay


todoMoreMenu =
    Todo.Menu.init >> XMTodoMoreMenu


editProject =
    GroupDoc.EditForm.forProject >> XMEditProject


editProjectSetName =
    GroupDoc.EditForm.setName >>> XMEditProject


editContext =
    GroupDoc.EditForm.forContext >> XMEditContext


editContextSetName =
    GroupDoc.EditForm.setName >>> XMEditContext


editTodo =
    Todo.Form.create >> XMEditTodo


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
