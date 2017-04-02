module Model.EditModel exposing (..)

import EditModel.Types exposing (..)
import Maybe.Extra as Maybe
import Model.Internal exposing (..)
import Model.ProjectList
import Project exposing (Project, ProjectName)
import Todo
import Todo.Types exposing (..)
import Toolkit.Helpers exposing (..)
import Toolkit.Operators exposing (..)
import FunctionExtra exposing (..)
import FunctionExtra.Operators exposing (..)
import Msg exposing (..)
import Model.Types exposing (..)


activateNewTodoMode : String -> ModelF
activateNewTodoMode text =
    setEditModel (NewTodo text)


setEditModelToEditTodo : Todo -> ModelF
setEditModelToEditTodo todo =
    updateEditModel (createEditTodoModel todo >> EditTodo)


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
        |> case getEditModel m of
            EditTodo model ->
                setEditModel (EditTodo ({ model | todoText = text }))

            _ ->
                identity


getMaybeEditTodoModel model =
    case getEditModel model of
        EditTodo model ->
            Just model

        _ ->
            Nothing


getEditNewTodoModel model =
    case getEditModel model of
        NewTodo model ->
            Just model

        _ ->
            Nothing


updateEditTodoProjectName : ProjectName -> ModelF
updateEditTodoProjectName projectName m =
    m
        |> case getEditModel m of
            EditTodo model ->
                setEditModel (EditTodo ({ model | projectName = projectName }))

            _ ->
                identity


deactivateEditingMode =
    setEditModel None


getProjectOfTodo : Todo -> Model -> Maybe Project
getProjectOfTodo todo model =
    Todo.getProjectId todo |> Model.ProjectList.getProjectByMaybeId # model


getProjectNameOfTodo : Todo -> Model -> ProjectName
getProjectNameOfTodo =
    getProjectOfTodo >>> Maybe.unwrap "" Project.getName
