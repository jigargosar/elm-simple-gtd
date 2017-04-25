module Todo.Form exposing (..)

import Context
import Document
import Project
import Time exposing (Time)
import Time.Format
import Toolkit.Helpers exposing (..)
import Toolkit.Operators exposing (..)
import Ext.Function exposing (..)
import Ext.Function.Infix exposing (..)
import List.Extra as List
import Maybe.Extra as Maybe
import Todo


type alias Model =
    { id : Document.Id
    , todoText : Todo.Text
    }


type Action
    = SetText String


createTextForm : Todo.Model -> Project.Name -> Context.Name -> Time -> Model
createTextForm todo projectName contextName now =
    let
        timeInMilli =
            Todo.getDueAt todo ?= now + Time.hour
    in
        { id = Document.getId todo
        , todoText = Todo.getText todo
        }



--set : FormField -> Form -> Form
--set field form =
--    case ( form, field ) of
--        ( TextForm form, TextFormField field ) ->
--            case field of
--                Text value ->
--                    TextForm { form | todoText = value }
--
--        _ ->
--            form


set : Action -> Model -> Model
set action model =
    case action of
        SetText value ->
            { model | todoText = value }
