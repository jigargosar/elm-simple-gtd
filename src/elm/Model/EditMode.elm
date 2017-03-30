module Model.EditMode exposing (..)

import Maybe.Extra as Maybe
import Todo exposing (Todo)
import Toolkit.Helpers exposing (..)
import Toolkit.Operators exposing (..)
import FunctionExtra exposing (..)
import Msg exposing (..)
import Types exposing (EditMode(..), Model, ModelF, createEditTodoMode)


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
    setEditModeTo (createEditTodoMode todo)


updateEditTodoText : String -> ModelF
updateEditTodoText text m =
    m
        |> case getEditMode m of
            EditTodoMode model ->
                setEditModeTo (EditTodoMode ({ model | todoText = text }))

            _ ->
                identity


deactivateEditingMode =
    setEditModeTo NotEditing


deactivateEditingModeFor : Todo -> ModelF
deactivateEditingModeFor todo model =
    case getEditTodoModeId model of
        Nothing ->
            model

        Just id ->
            model
                |> if Todo.hasId id todo then
                    deactivateEditingMode
                   else
                    identity



--    case getEditMode model of
--        EditTodoMode { todoId } ->
--            if Todo.hasId todoId todo then
--                deactivateEditingMode model
--            else
--                model
--
--        _ ->
--            model


getEditTodoModeId =
    getEditTodoModeModel >> Maybe.map (.todoId)


getEditTodoModeModel model =
    case getEditMode model of
        EditTodoMode model ->
            Just model

        _ ->
            Nothing
