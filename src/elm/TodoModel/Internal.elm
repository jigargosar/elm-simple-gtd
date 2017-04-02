module TodoModel.Internal exposing (..)

import Project
import TodoModel.Types exposing (..)
import Toolkit.Helpers exposing (..)
import Toolkit.Operators exposing (..)
import FunctionExtra exposing (..)


type alias Model =
    TodoModel


type alias ModelF =
    Model -> Model


type alias ModelField =
    TodoField


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
        TodoDoneField done ->
            { model | done = done }

        TodoDeletedField deleted ->
            { model | deleted = deleted }

        TodoTextField text ->
            { model | text = text }

        TodoContextField context ->
            { model | context = context }

        TodoProjectIdField projectId ->
            { model | projectId = projectId }

        TodoProjectField project ->
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
