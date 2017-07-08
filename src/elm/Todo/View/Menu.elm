module Todo.View.Menu exposing (..)

import Context
import Document exposing (Document)
import Menu
import Model
import Msg
import Project
import Todo
import Todo.FormTypes exposing (TodoGroupFrom)
import Toolkit.Operators exposing (..)
import Html exposing (..)
import Todo.GroupForm
import Todo.Msg


createProjectMenuConfig : TodoGroupFrom -> Model.Model -> Menu.Config Project.Model Msg.Msg
createProjectMenuConfig ({ todoId, projectId } as form) model =
    { onSelect =
        Document.getId
            >> Todo.SetProjectId
            >> Todo.Msg.OnUpdateTodoAndMaybeSelectedAndDeactivateEditingMode todoId
            >> Msg.OnTodoMsg
    , isSelected = Document.hasId projectId
    , itemKey = getMenuKey "project"
    , itemSearchText = Project.getName
    , itemView = Project.getName >> text
    , onStateChanged = Msg.OnEditTodoProjectMenuStateChanged form
    , noOp = Model.noop
    , onOutsideMouseDown = Msg.OnDeactivateEditingMode
    }


createContextMenuConfig : TodoGroupFrom -> Model.Model -> Menu.Config Context.Model Msg.Msg
createContextMenuConfig ({ todoId, contextId } as form) model =
    { onSelect =
        Document.getId
            >> Todo.SetContextId
            >> Todo.Msg.OnUpdateTodoAndMaybeSelectedAndDeactivateEditingMode todoId
            >> Msg.OnTodoMsg
    , isSelected = Document.hasId contextId
    , itemKey = getMenuKey "context"
    , itemSearchText = Context.getName
    , itemView = Context.getName >> text
    , onStateChanged = Msg.OnEditTodoContextMenuStateChanged form
    , noOp = Model.noop
    , onOutsideMouseDown = Msg.OnDeactivateEditingMode
    }


project form model =
    Menu.view (Model.getActiveProjects model)
        form.menuState
        (createProjectMenuConfig form model)


context form model =
    Menu.view (Model.getActiveContexts model)
        form.menuState
        (createContextMenuConfig form model)


getMenuKey : String -> Document x -> String
getMenuKey prefix =
    Document.getId >> String.append "-menu-key-" >> String.append prefix
