module Model.Msg exposing (..)

import ExclusiveMode.Types exposing (ExclusiveMode(XMNewTodo))
import Todo.Form
import Msg
import Todo.FormTypes exposing (AddTodoFormMode(ATFM_AddByFocusInEntity))


onNewTodoModeWithFocusInEntityAsReference model =
    Todo.Form.createAddTodoForm ATFM_AddByFocusInEntity |> XMNewTodo |> Msg.OnStartExclusiveMode
