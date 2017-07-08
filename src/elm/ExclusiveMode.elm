module ExclusiveMode exposing (..)

import Entity.Types
import ExclusiveMode.Types exposing (ExclusiveMode(..))
import GroupDoc.EditForm
import GroupDoc.FormTypes exposing (GroupDocEditModel)
import LaunchBar.Form
import Menu
import Todo.Menu
import Todo.NewForm
import Todo.GroupForm
import X.Function.Infix exposing (..)
import Todo.Form
import Todo.ReminderForm


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
