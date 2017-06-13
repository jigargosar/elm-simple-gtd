module Todo.View.Menu exposing (..)

import Context
import Document exposing (Document)
import Menu
import Model exposing (commonMsg)
import Project
import Todo
import Toolkit.Helpers exposing (..)
import Toolkit.Operators exposing (..)
import Ext.Function exposing (..)
import Ext.Function.Infix exposing (..)
import List.Extra as List
import Maybe.Extra as Maybe
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Html.Events.Extra exposing (onClickStopPropagation)
import Todo.GroupForm


createProjectMenuConfig : Todo.GroupForm.Model -> Model.Model -> Menu.Config Project.Model Model.Msg
createProjectMenuConfig ({ todo } as form) model =
    { onSelect = Model.SetTodoProject # todo
    , isSelected = Document.hasId (Todo.getProjectId todo)
    , itemKey = getMenuKey "project"
    , itemSearchText = Project.getName
    , itemView = Project.getName >> text
    , onStateChanged = Model.OnEditTodoProjectMenuStateChanged form
    , noOp = commonMsg.noOp
    , onOutsideMouseDown = Model.OnDeactivateEditingMode
    }


createContextMenuConfig : Todo.GroupForm.Model -> Model.Model -> Menu.Config Context.Model Model.Msg
createContextMenuConfig ({ todo } as form) model =
    { onSelect = Model.SetTodoContext # todo
    , isSelected = Document.hasId (Todo.getContextId todo)
    , itemKey = getMenuKey "context"
    , itemSearchText = Context.getName
    , itemView = Context.getName >> text
    , onStateChanged = Model.OnEditTodoContextMenuStateChanged form
    , noOp = commonMsg.noOp
    , onOutsideMouseDown = Model.OnDeactivateEditingMode
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
