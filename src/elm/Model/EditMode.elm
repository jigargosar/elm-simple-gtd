module Model.EditMode exposing (..)

import Todo exposing (Todo)
import Toolkit.Helpers exposing (..)
import Toolkit.Operators exposing (..)
import FunctionExtra exposing (..)
import Msg exposing (..)
import Types exposing (EditMode(..), Model, ModelF)


setEditModeTo : EditMode -> ModelF
setEditModeTo editMode m =
    { m | editMode = editMode }


getEditMode : Model -> EditMode
getEditMode =
    (.editMode)


activateEditNewTodoMode : String -> ModelF
activateEditNewTodoMode text =
    setEditModeTo (EditNewTodoMode text)


activateEditTodoMode : Todo -> ModelF
activateEditTodoMode todo =
    setEditModeTo (EditTodoMode todo)


updateEditTodoText : String -> ModelF
updateEditTodoText text m =
    case getEditMode m of
        EditTodoMode todo ->
            setEditModeTo (EditTodoMode (Todo.setText text todo)) m

        _ ->
            m


deactivateEditingMode =
    setEditModeTo NotEditing


deactivateEditingModeFor : Todo -> ModelF
deactivateEditingModeFor todo model =
    case getEditMode model of
        EditTodoMode editingTodo ->
            if Todo.equalById todo editingTodo then
                deactivateEditingMode model
            else
                model

        _ ->
            model
