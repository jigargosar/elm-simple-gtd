module Todo.NewForm exposing (..)

import Context
import Document
import Form
import Project
import Toolkit.Helpers exposing (..)
import Toolkit.Operators exposing (..)
import Ext.Function exposing (..)
import Ext.Function.Infix exposing (..)
import List.Extra as List
import Maybe.Extra as Maybe
import Todo


type alias Model =
    Form.Model


type Field
    = Text


create : Todo.Text -> Form.Model
create text =
    Form.init
        |> Form.set "text" text


set : Field -> String -> Form.ModelF
set field value =
    case field of
        Text ->
            Form.set "text" value


getText =
    Form.get "text"
