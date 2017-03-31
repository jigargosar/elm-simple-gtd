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
import Types exposing (EditMode(..), EditTodoModel, Model, ModelF)


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


getEditTodoModel model =
    case getEditMode model of
        EditTodoMode model ->
            Just model

        _ ->
            Nothing


getEditTodoModelForTodoHelp : Maybe EditTodoModel -> Todo -> Maybe EditTodoModel
getEditTodoModelForTodoHelp maybeETM todo =
    case maybeETM of
        Just etm ->
            if Todo.equalById etm.todo todo then
                Just etm
            else
                Nothing

        Nothing ->
            Nothing



getEditTodoModelForTodo = getEditTodoModel >> getEditTodoModelForTodoHelp

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
        >> uncurry3 EditTodoModel
        >> EditTodoMode


getProjectOfTodo : Todo -> Model -> Maybe Project
getProjectOfTodo todo model =
    Todo.getProjectId todo |> Model.ProjectList.getProjectByMaybeId # model


getProjectNameOfTodo : Todo -> Model -> ProjectName
getProjectNameOfTodo =
    getProjectOfTodo >>> Maybe.unwrap "" Project.getName
