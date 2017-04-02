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
        SetDone done ->
            { model | done = done }

        SetDeleted deleted ->
            { model | deleted = deleted }

        SetText text ->
            { model | text = text }

        SetContext context ->
            { model | context = context }

        SetProjectId projectId ->
            { model | projectId = projectId }

        SetProject project ->
            set (SetProjectId (Just (Project.getId project))) model


setFields : List ModelField -> ModelF
setFields fields =
    List.foldl set # fields
