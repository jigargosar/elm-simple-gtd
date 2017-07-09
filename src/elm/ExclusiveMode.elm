module ExclusiveMode exposing (..)

import Entity.Types exposing (EntityType(..), GroupEntityType(..))
import ExclusiveMode.Types exposing (ExclusiveMode(..))
import GroupDoc.EditForm
import Todo.Menu
import X.Function.Infix exposing (..)
import Todo.Form


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


createEntityEditForm : EntityType -> ExclusiveMode
createEntityEditForm entity =
    case entity of
        GroupEntity g ->
            case g of
                ContextEntity model ->
                    editContext model

                ProjectEntity model ->
                    editProject model

        TodoEntity model ->
            editTodo model
