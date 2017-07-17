module Todo.View.Menu exposing (..)

import Context
import Document exposing (Document)
import Menu
import Model
import Model.GroupDocStore
import Msg
import Project
import Html exposing (..)
import Todo.FormTypes exposing (..)
import Todo.Msg
import Todo.Types exposing (TodoAction(TA_SetContextId, TA_SetProjectId))
import TodoMsg
import Types exposing (AppModel)
import XMMsg


createProjectMenuConfig : TodoForm -> AppModel -> Menu.Config Project.Model Msg.AppMsg
createProjectMenuConfig form model =
    { onSelect =
        Document.getId
            >> TA_SetProjectId
            >> Todo.Msg.OnUpdateTodoAndMaybeSelectedAndDeactivateEditingMode form.id
            >> Msg.OnTodoMsg
    , isSelected = Document.hasId form.projectId
    , itemKey = getMenuKey "project"
    , itemSearchText = Project.getName
    , itemView = Project.getName >> text
    , onStateChanged = TodoMsg.onSetTodoFormMenuState form
    , noOp = Model.noop
    , onOutsideMouseDown = XMMsg.revertExclusiveMode
    }


createContextMenuConfig : TodoForm -> AppModel -> Menu.Config Context.Model Msg.AppMsg
createContextMenuConfig form model =
    { onSelect =
        Document.getId
            >> TA_SetContextId
            >> Todo.Msg.OnUpdateTodoAndMaybeSelectedAndDeactivateEditingMode form.id
            >> Msg.OnTodoMsg
    , isSelected = Document.hasId form.contextId
    , itemKey = getMenuKey "context"
    , itemSearchText = Context.getName
    , itemView = Context.getName >> text
    , onStateChanged = TodoMsg.onSetTodoFormMenuState form
    , noOp = Model.noop
    , onOutsideMouseDown = XMMsg.revertExclusiveMode
    }


project form model =
    Menu.view (Model.GroupDocStore.getActiveProjects model)
        form.menuState
        (createProjectMenuConfig form model)


context form model =
    Menu.view (Model.GroupDocStore.getActiveContexts model)
        form.menuState
        (createContextMenuConfig form model)


getMenuKey : String -> Document x -> String
getMenuKey prefix =
    Document.getId >> String.append "-menu-key-" >> String.append prefix
