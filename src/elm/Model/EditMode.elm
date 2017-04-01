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


activateNewTodoMode : String -> ModelF
activateNewTodoMode text =
    setEditMode (NewTodo text)


setEditModeToEditTodo : Todo -> ModelF
setEditModeToEditTodo todo =
    updateEditMode (createEditTodoModel todo >> EditTodo)


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
            EditTodo model ->
                setEditMode (EditTodo ({ model | todoText = text }))

            _ ->
                identity


getEditTodoModel model =
    case getEditMode model of
        EditTodo model ->
            Just model

        _ ->
            Nothing


getEditNewTodoModel model =
    case getEditMode model of
        NewTodo model ->
            Just model

        _ ->
            Nothing


updateEditTodoProjectName : ProjectName -> ModelF
updateEditTodoProjectName projectName m =
    m
        |> case getEditMode m of
            EditTodo model ->
                setEditMode (EditTodo ({ model | projectName = projectName }))

            _ ->
                identity


deactivateEditingMode =
    setEditMode None


getProjectOfTodo : Todo -> Model -> Maybe Project
getProjectOfTodo todo model =
    Todo.getProjectId todo |> Model.ProjectList.getProjectByMaybeId # model


getProjectNameOfTodo : Todo -> Model -> ProjectName
getProjectNameOfTodo =
    getProjectOfTodo >>> Maybe.unwrap "" Project.getName
