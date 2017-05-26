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
    | ReferenceTodoId


create : Todo.Id -> Todo.Text -> Form.Model
create referenceTodoId text =
    Form.init
        |> Form.set "text" text
        |> Form.set "referenceTodoId" referenceTodoId


set : Field -> String -> Form.ModelF
set field value =
    case field of
        Text ->
            Form.set "text" value

        ReferenceTodoId ->
            Form.set "referenceTodoId" value


getText =
    Form.get "text"
