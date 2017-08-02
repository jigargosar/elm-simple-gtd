module Todo.GroupEditView exposing (..)

import Document exposing (..)
import GroupDoc
import Html exposing (..)
import Menu
import Menu.Types exposing (MenuState)
import Models.GroupDocStore


type alias Config msg =
    { onSetProject : DocId -> msg
    , onSetContext : DocId -> msg
    , onSetTodoFormMenuState : MenuState -> msg
    , noop : msg
    , revertExclusiveMode : msg
    }


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



--createContextMenuConfig : TodoForm -> AppModel -> Menu.Config GroupDoc.Model Msg.AppMsg


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
    Menu.view (Models.GroupDocStore.getActiveProjects model)
        form.menuState
        (createProjectMenuConfig config form)


context config form model =
    Menu.view (Models.GroupDocStore.getActiveContexts model)
        form.menuState
        (createContextMenuConfig config form)


getMenuKey : String -> Document x -> String
getMenuKey prefix =
    Document.getId >> String.append "-menu-key-" >> String.append prefix
