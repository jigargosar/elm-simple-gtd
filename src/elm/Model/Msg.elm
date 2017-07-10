module Model.Msg exposing (..)

import ExclusiveMode.Types exposing (ExclusiveMode(XMNewTodo))
import Todo.NewForm
import Msg


onNewTodoModeWithFocusInEntityAsReference model =
    Todo.NewForm.create (model.focusInEntity) "" |> XMNewTodo |> Msg.OnStartExclusiveMode
