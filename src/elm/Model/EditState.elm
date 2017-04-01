module Model.EditState exposing (..)

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
    setEditState (NewTodo text)


setEditStateToEditTodo : Todo -> ModelF
setEditStateToEditTodo todo =
    updateEditState (createEditTodoModel todo >> EditTodo)


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
        |> case getEditState m of
            EditTodo model ->
                setEditState (EditTodo ({ model | todoText = text }))

            _ ->
                identity


getEditTodoModel model =
    case getEditState model of
        EditTodo model ->
            Just model

        _ ->
            Nothing


getEditNewTodoModel model =
    case getEditState model of
        NewTodo model ->
            Just model

        _ ->
            Nothing


updateEditTodoProjectName : ProjectName -> ModelF
updateEditTodoProjectName projectName m =
    m
        |> case getEditState m of
            EditTodo model ->
                setEditState (EditTodo ({ model | projectName = projectName }))

            _ ->
                identity


deactivateEditingMode =
    setEditState None


getProjectOfTodo : Todo -> Model -> Maybe Project
getProjectOfTodo todo model =
    Todo.getProjectId todo |> Model.ProjectList.getProjectByMaybeId # model


getProjectNameOfTodo : Todo -> Model -> ProjectName
getProjectNameOfTodo =
    getProjectOfTodo >>> Maybe.unwrap "" Project.getName
