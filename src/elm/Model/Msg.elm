module Model.Msg exposing (..)

import ExclusiveMode.Types exposing (ExclusiveMode(XMNewTodo))
import Todo.Form
import Msg
import Todo.FormTypes exposing (AddTodoFormMode(NTFM_NewTodo))


onNewTodoModeWithFocusInEntityAsReference model =
    Todo.Form.createNewTodoForm NTFM_NewTodo (model.focusInEntity) "" |> XMNewTodo |> Msg.OnStartExclusiveMode
