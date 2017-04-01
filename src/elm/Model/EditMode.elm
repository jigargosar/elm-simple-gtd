module Model.EditMode exposing (..)

import Maybe.Extra as Maybe
import Model.Internal exposing (..)
import Model.ProjectList
import Project exposing (Project, ProjectName)
import Todo exposing (Todo)
import Toolkit.Helpers exposing (..)
import Toolkit.Operators exposing (..)
import FunctionExtra exposing (..)
import FunctionExtra.Operators exposing (..)
import Msg exposing (..)
import Model.Types exposing (..)


activateEditNewTodoMode : String -> ModelF
activateEditNewTodoMode text =
    setEditMode (EditNewTodoMode text)


startEditingTodo : Todo -> ModelF
startEditingTodo todo =
    updateEditMode (createEditTodoModel todo >> EditTodoMode)


createEditTodoModel : Todo -> Model -> EditTodoModel
createEditTodoModel todo model =
    todo
        |> apply3
            ( identity
            , Todo.getText
            , getProjectNameOfTodo # model
            )
        >> uncurry3 EditTodoModel


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


getEditNewTodoModel model =
    case getEditMode model of
        EditNewTodoMode model ->
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


getProjectOfTodo : Todo -> Model -> Maybe Project
getProjectOfTodo todo model =
    Todo.getProjectId todo |> Model.ProjectList.getProjectByMaybeId # model


getProjectNameOfTodo : Todo -> Model -> ProjectName
getProjectNameOfTodo =
    getProjectOfTodo >>> Maybe.unwrap "" Project.getName
