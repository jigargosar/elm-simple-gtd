module Todo.View.Menu exposing (..)

import Context
import Document exposing (Document)
import Menu
import Model
import Msg
import Project
import Stores
import Html exposing (..)
import Todo.Form exposing (..)
import Todo.Msg
import Todo.Types exposing (TodoAction(TA_SetContextId, TA_SetProjectId))
import Types exposing (AppModel)


createProjectMenuConfig : TodoEditForm -> AppModel -> Menu.Config Project.Model Msg.Msg
createProjectMenuConfig ({ todoId, projectId } as form) model =
    { onSelect =
        Document.getId
            >> TA_SetProjectId
            >> Todo.Msg.OnUpdateTodoAndMaybeSelectedAndDeactivateEditingMode todoId
            >> Msg.OnTodoMsg
    , isSelected = Document.hasId projectId
    , itemKey = getMenuKey "project"
    , itemSearchText = Project.getName
    , itemView = Project.getName >> text
    , onStateChanged = SetTodoMenuState >> Msg.OnUpdateTodoForm form
    , noOp = Model.noop
    , onOutsideMouseDown = Msg.OnDeactivateEditingMode
    }


createContextMenuConfig : TodoEditForm -> AppModel -> Menu.Config Context.Model Msg.Msg
createContextMenuConfig ({ todoId, contextId } as form) model =
    { onSelect =
        Document.getId
            >> TA_SetContextId
            >> Todo.Msg.OnUpdateTodoAndMaybeSelectedAndDeactivateEditingMode todoId
            >> Msg.OnTodoMsg
    , isSelected = Document.hasId contextId
    , itemKey = getMenuKey "context"
    , itemSearchText = Context.getName
    , itemView = Context.getName >> text
    , onStateChanged = SetTodoMenuState >> Msg.OnUpdateTodoForm form
    , noOp = Model.noop
    , onOutsideMouseDown = Msg.OnDeactivateEditingMode
    }


project form model =
    Menu.view (Stores.getActiveProjects model)
        form.menuState
        (createProjectMenuConfig form model)


context form model =
    Menu.view (Stores.getActiveContexts model)
        form.menuState
        (createContextMenuConfig form model)


getMenuKey : String -> Document x -> String
getMenuKey prefix =
    Document.getId >> String.append "-menu-key-" >> String.append prefix
