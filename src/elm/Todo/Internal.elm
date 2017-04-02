module Todo.Internal exposing (..)

import Project
import Todo.Types exposing (..)
import Toolkit.Helpers exposing (..)
import Toolkit.Operators exposing (..)
import FunctionExtra exposing (..)


type alias Model =
    Todo


type alias ModelF =
    Model -> Model


type alias ModelField =
    TodoAction


getDeleted : Model -> Bool
getDeleted =
    (.deleted)


setDeleted : Bool -> ModelF
setDeleted deleted model =
    { model | deleted = deleted }


updateDeleted : (Model -> Bool) -> ModelF
updateDeleted updater model =
    setDeleted (updater model) model


set : ModelField -> ModelF
set field model =
    case field of
        SetTodoDone done ->
            { model | done = done }

        SetTodoDeleted deleted ->
            { model | deleted = deleted }

        SetTodoText text ->
            { model | text = text }

        SetTodoContext context ->
            { model | context = context }

        SetTodoProjectId projectId ->
            { model | projectId = projectId }

        SetTodoProject project ->
            { model | projectId = project ?|> Project.getId }


update : (Model -> ModelField) -> ModelF
update updater model =
    set (updater model) model


updateFields : List (Model -> ModelField) -> ModelF
updateFields fields =
    List.foldl update # fields


setFields : List ModelField -> ModelF
setFields fields =
    List.foldl set # fields
