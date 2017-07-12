module Model.Msg exposing (..)

import ExclusiveMode.Types exposing (ExclusiveMode(XMNewTodo))
import Todo.Form
import Msg


onNewTodoModeWithFocusInEntityAsReference model =
    Todo.Form.createNewTodoForm (model.focusInEntity) "" |> XMNewTodo |> Msg.OnStartExclusiveMode
