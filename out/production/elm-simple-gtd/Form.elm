module Form exposing (..)

import Dict exposing (Dict)
import Toolkit.Helpers exposing (..)
import Toolkit.Operators exposing (..)
import Ext.Function exposing (..)
import Ext.Function.Infix exposing (..)
import List.Extra as List
import Maybe.Extra as Maybe


type alias Model =
    { fields : Fields
    }


type alias ModelF =
    Model -> Model


type alias Fields =
    Dict String String


init =
    { fields = Dict.empty }


set name value =
    updateFields (Dict.insert name value)


get name =
    getFields >> Dict.get name >>?= ""


getFields : Model -> Fields
getFields =
    (.fields)


setFields : Fields -> ModelF
setFields fields model =
    { model | fields = fields }


updateFieldsM : (Model -> Fields) -> ModelF
updateFieldsM updater model =
    setFields (updater model) model


updateFields : (Fields -> Fields) -> ModelF
updateFields updater model =
    setFields (updater (getFields model)) model
