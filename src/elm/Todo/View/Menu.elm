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
import Todo.ProjectsForm


createContextMenuConfig : Todo.Model -> Model.Model -> Menu.Config Context.Model Model.Msg
createContextMenuConfig todo model =
    { onSelect = Model.SetTodoContext # todo
    , isSelected = Document.hasId (Todo.getContextId todo)
    , itemKey = Document.getId >> String.append "context-id-"
    , domId = "context-menu"
    , itemView = Context.getName >> text
    , maybeFocusKey = Nothing
    , onFocusIndexChanged = (\_ -> commonMsg.noOp)
    , noOp = commonMsg.noOp
    , onOutsideMouseDown = Model.DeactivateEditingMode
    }


context form model =
    createContextMenuConfig form model
        |> Menu.view (Model.getActiveContexts model)


createProjectMenuConfig : Todo.ProjectsForm.Model -> Model.Model -> Menu.Config Project.Model Model.Msg
createProjectMenuConfig ({ todo, maybeFocusKey } as form) model =
    { onSelect = Model.SetTodoProject # todo
    , isSelected = Document.hasId (Todo.getProjectId todo)
    , itemKey = Document.getId >> String.append "project-id-"
    , domId = "project-menu"
    , itemView = Project.getName >> text
    , maybeFocusKey = maybeFocusKey
    , onFocusIndexChanged = Model.UpdateEditTodoProjectMaybeFocusKey form
    , noOp = commonMsg.noOp
    , onOutsideMouseDown = Model.DeactivateEditingMode
    }


project form model =
    createProjectMenuConfig form model
        |> Menu.view (Model.getActiveProjects model)
