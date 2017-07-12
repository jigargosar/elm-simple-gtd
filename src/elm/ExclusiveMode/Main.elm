module ExclusiveMode.Main exposing (..)

import DomPorts exposing (autoFocusInputRCmd)
import ExclusiveMode.Types exposing (..)
import Model.Internal exposing (setEditMode, setTodoEXMode, setTodoEditForm)
import Return exposing (map)
import Todo.Form


start exclusiveMode =
    case exclusiveMode of
        XMNewTodo form ->
            Return.map (setEditMode exclusiveMode)
                >> autoFocusInputRCmd

        XMTodoEdit todo t ->
            map
                (setTodoEXMode todo t
                    >> createAndSetTodoEditForm todo
                )

        _ ->
            identity


createAndSetTodoEditForm todo model =
    Model.Internal.setTodoEditForm (Todo.Form.createEditTodoForm model.now todo) model
