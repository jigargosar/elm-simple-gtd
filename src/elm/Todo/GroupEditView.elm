module Todo.GroupEditView exposing (..)

import Document exposing (Document)
import Document.Types exposing (DocId, getDocId)
import GroupDoc
import Html exposing (..)
import Menu
import Menu.Types exposing (MenuState)
import Model.GroupDocStore


type alias Config msg =
    { onSetProject : DocId -> msg
    , onSetContext : DocId -> msg
    , onSetTodoFormMenuState : MenuState -> msg
    , noop : msg
    , revertExclusiveMode : msg
    }



--createProjectMenuConfig : TodoForm -> AppModel -> Menu.Config Project.Model Msg.AppMsg


createProjectMenuConfig config form =
    { onSelect = config.onSetProject form.id
    , isSelected = Document.hasId form.projectId
    , itemKey = getMenuKey "project"
    , itemSearchText = GroupDoc.getName
    , itemView = GroupDoc.getName >> text
    , onStateChanged = config.onSetTodoFormMenuState form
    , noOp = config.noop
    , onOutsideMouseDown = config.revertExclusiveMode
    }



--createContextMenuConfig : TodoForm -> AppModel -> Menu.Config Context.Model Msg.AppMsg


createContextMenuConfig config form =
    { onSelect = config.onSetContext form.id
    , isSelected = Document.hasId form.contextId
    , itemKey = getMenuKey "context"
    , itemSearchText = GroupDoc.getName
    , itemView = GroupDoc.getName >> text
    , onStateChanged = config.onSetTodoFormMenuState form
    , noOp = config.noop
    , onOutsideMouseDown = config.revertExclusiveMode
    }


project config form model =
    Menu.view (Model.GroupDocStore.getActiveProjects model)
        form.menuState
        (createProjectMenuConfig config form)


context config form model =
    Menu.view (Model.GroupDocStore.getActiveContexts model)
        form.menuState
        (createContextMenuConfig config form)


getMenuKey : String -> Document x -> String
getMenuKey prefix =
    getDocId >> String.append "-menu-key-" >> String.append prefix
