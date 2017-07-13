module Model.Msg exposing (..)

import ExclusiveMode.Types exposing (ExclusiveMode(XMNewTodo))
import Todo.Form
import Msg
import Todo.FormTypes exposing (AddTodoFormMode(ATFM_AddByFocusInEntity))


onNewTodoModeWithFocusInEntityAsReference model =
    Todo.Form.createNewTodoForm ATFM_AddByFocusInEntity (model.focusInEntity) "" |> XMNewTodo |> Msg.OnStartExclusiveMode
