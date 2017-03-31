module Model.EditMode exposing (..)

import Maybe.Extra as Maybe
import Model.ProjectList
import Project exposing (Project, ProjectName)
import Todo exposing (Todo)
import Toolkit.Helpers exposing (..)
import Toolkit.Operators exposing (..)
import FunctionExtra exposing (..)
import FunctionExtra.Operators exposing (..)
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
    updateEditMode (createEditTodoMode todo)


updateEditTodoText : String -> ModelF
updateEditTodoText text m =
    m
        |> case getEditMode m of
            EditTodoMode model ->
                setEditMode (EditTodoMode ({ model | todoText = text }))

            _ ->
                identity


getEditTodoModeModel model =
    case getEditMode model of
        EditTodoMode model ->
            Just model

        _ ->
            Nothing


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


createEditTodoMode : Todo -> Model -> EditMode
createEditTodoMode todo model =
    todo
        |> apply3
            ( identity
            , Todo.getText
            , getProjectNameOfTodo # model
            )
        >> uncurry3 EditTodoModeModel
        >> EditTodoMode


getProjectOfTodo : Todo -> Model -> Maybe Project
getProjectOfTodo todo model =
    Todo.getProjectId todo |> Model.ProjectList.getProjectByMaybeId # model


getProjectNameOfTodo : Todo -> Model -> ProjectName
getProjectNameOfTodo =
    getProjectOfTodo >>> Maybe.unwrap "" Project.getName
