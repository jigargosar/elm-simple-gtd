module EditMode exposing (..)

import Context
import Document
import Project
import Todo
import Todo.NewForm
import Toolkit.Helpers exposing (..)
import Toolkit.Operators exposing (..)
import Ext.Function exposing (..)
import Ext.Function.Infix exposing (..)
import List.Extra as List
import Maybe.Extra as Maybe
import Time exposing (Time)
import Time.Format
import Todo.Form
import Todo.ReminderForm


type alias TodoForm =
    Todo.Form.Model


type alias EditContextModel =
    { id : Document.Id
    , name : Context.Name
    }


type alias EntityForm =
    EditContextModel


type alias EditProjectModel =
    { id : Document.Id
    , name : Project.Name
    }


type alias NewTodoModel =
    Todo.Text


type alias RemoteSyncForm =
    { uri : String }


type EditMode
    = NewTodo Todo.NewForm.Model
    | TodoForm Todo.Form.Model
    | TodoReminderForm Todo.ReminderForm.Model
    | EditContext EditContextModel
    | EditProject EditProjectModel
    | RemoteSync RemoteSyncForm
    | None
    | SwitchView
    | SwitchToGroupedView


none =
    None


editContextMode model =
    EditContext { id = Document.getId model, name = Context.getName model }


editContextSetName name ecm =
    EditContext { ecm | name = name }


editProjectMode model =
    EditProject { id = Document.getId model, name = Project.getName model }


editProjectSetName name epm =
    EditProject { epm | name = name }


getMaybeEditTodoModel model =
    case model of
        TodoForm model ->
            Just model

        _ ->
            Nothing


getNewTodoModel model =
    case model of
        NewTodo model ->
            Just model

        _ ->
            Nothing
