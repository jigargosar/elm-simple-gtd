module TodoModel.Internal exposing (..)

import TodoModel.Types exposing (..)
import Toolkit.Helpers exposing (..)
import Toolkit.Operators exposing (..)
import FunctionExtra exposing (..)


type alias Model =
    TodoModel


type alias ModelF =
    Model -> Model


getDeleted : Model -> Bool
getDeleted =
    (.deleted)


setDeleted : Bool -> ModelF
setDeleted deleted model =
    { model | deleted = deleted }


updateDeleted : (Model -> Bool) -> ModelF
updateDeleted updater model =
    setDeleted (updater model) model


