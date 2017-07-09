module Model.Msg exposing (..)

import ExclusiveMode.Types exposing (ExclusiveMode(XMNewTodo))
import Todo.NewForm
import Toolkit.Helpers exposing (..)
import Toolkit.Operators exposing (..)
import X.Function exposing (..)
import X.Function.Infix exposing (..)
import List.Extra as List
import Maybe.Extra as Maybe
import Msg


onNewTodoModeWithFocusInEntityAsReference model =
    Todo.NewForm.create (model.focusInEntity) "" |> XMNewTodo |> Msg.OnStartExclusiveMode
