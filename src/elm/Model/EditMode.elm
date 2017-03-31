module Model.EditMode exposing (..)

import Maybe.Extra as Maybe
import Project exposing (ProjectName)
import Todo exposing (Todo)
import Toolkit.Helpers exposing (..)
import Toolkit.Operators exposing (..)
import FunctionExtra exposing (..)
import Msg exposing (..)
import Types exposing (EditMode(..), EditTodoModeModel, Model, ModelF)


activateEditNewTodoMode : String -> ModelF
activateEditNewTodoMode text =
    setEditMode (EditNewTodoMode text)


getEditMode : Model -> EditMode
getEditMode =
    (.editMode)


setEditMode : EditMode -> ModelF
setEditMode editMode model =
    { model | editMode = editMode }


updateEditMode : (Model -> EditMode) -> ModelF
updateEditMode updater model =
    setEditMode (updater model) model


activateEditTodoMode : Todo -> ModelF
activateEditTodoMode todo =
    setEditMode (createEditTodoMode todo)


updateEditTodoText : String -> ModelF
updateEditTodoText text m =
    m
        |> case getEditMode m of
            EditTodoMode model ->
                setEditMode (EditTodoMode ({ model | todoText = text }))

            _ ->
                identity


updateEditTodoProjectName : ProjectName -> ModelF
updateEditTodoProjectName projectName m =
    m
        |> case getEditMode m of
            EditTodoMode model ->
                setEditMode (EditTodoMode ({ model | projectName = projectName }))

            _ ->
                identity


deactivateEditingMode =
    setEditMode NotEditing


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


createEditTodoMode : Todo -> EditMode
createEditTodoMode =
    apply3 ( Todo.getId, Todo.getText, (\_ -> "Foo") )
        >> uncurry3 EditTodoModeModel
        >> EditTodoMode
