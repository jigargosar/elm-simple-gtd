module Model.ExMode exposing (..)

import Context
import Document.Types exposing (getDocId)
import Entity.Types exposing (..)
import ExclusiveMode.Types exposing (ExclusiveMode(..))
import LaunchBar.Models
import Menu
import Model.Internal exposing (setEditMode, updateEditModeM)
import Project
import Return
import Time exposing (Time)
import Todo
import Todo.Form
import Todo.NewForm
import Todo.ReminderForm
import Types exposing (AppModel, ModelF)
import Stores
import Todo.Types exposing (TodoAction(..), TodoDoc)
import X.Record exposing (set)
import Toolkit.Operators exposing (..)
import Toolkit.Helpers exposing (..)


activateNewTodoModeWithFocusInEntityAsReference : ModelF
activateNewTodoModeWithFocusInEntityAsReference model =
    setEditMode (Todo.NewForm.create (model.focusInEntity) "" |> XMNewTodo) model


startEditingReminder : TodoDoc -> ModelF
startEditingReminder todo =
    updateEditModeM (.now >> Todo.ReminderForm.create todo >> XMEditTodoReminder)


showMainMenu =
    setEditMode (Menu.initState |> XMMainMenu)
