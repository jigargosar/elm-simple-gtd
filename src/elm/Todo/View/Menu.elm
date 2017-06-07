module Todo.View.Menu exposing (..)

import Context
import Document
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
import Todo.GroupListForm


createProjectMenuConfig : Todo.GroupListForm.Model -> Model.Model -> Menu.Config Project.Model Model.Msg
createProjectMenuConfig ({ todo } as form) model =
    { onSelect = Model.SetTodoProject # todo
    , isSelected = Document.hasId (Todo.getProjectId todo)
    , itemKey = Document.getId >> String.append "project-id-"
    , domId = "project-menu"
    , itemView = Project.getName >> text
    , onStateChanged = Model.OnEditTodoProjectMenuStateChanged form
    , noOp = commonMsg.noOp
    , onOutsideMouseDown = Model.DeactivateEditingMode
    }


project form model =
    createProjectMenuConfig form model
        |> Menu.view (Model.getActiveProjects model) form.menuState


createContextMenuConfig : Todo.GroupListForm.Model -> Model.Model -> Menu.Config Context.Model Model.Msg
createContextMenuConfig ({ todo } as form) model =
    { onSelect = Model.SetTodoContext # todo
    , isSelected = Document.hasId (Todo.getContextId todo)
    , itemKey = Document.getId >> String.append "context-id-"
    , domId = "context-menu"
    , itemView = Context.getName >> text
    , onStateChanged = Model.OnEditTodoContextMenuStateChanged form
    , noOp = commonMsg.noOp
    , onOutsideMouseDown = Model.DeactivateEditingMode
    }


context form model =
    createContextMenuConfig form model
        |> Menu.view (Model.getActiveContexts model) form.menuState
