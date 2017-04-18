module Todo.Edit exposing (..)

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


type alias Form =
    { id : Document.Id
    , todoText : Todo.Text
    , projectName : Project.Name
    , contextName : Context.Name
    , date : String
    , time : String
    }


type Field
    = ProjectName
    | ContextName
    | Text
    | Date
    | Time


create : Todo.Model -> Project.Name -> Context.Name -> Form
create todo projectName contextName =
    let
        time =
            Todo.getTime todo
    in
        { id = Document.getId todo
        , todoText = Todo.getText todo
        , projectName = projectName
        , contextName = contextName
        , date = time |> (Time.Format.format "%Y-%m-%d")
        , time = time |> (Time.Format.format "%H:%M")
        }


set : Field -> String -> Form -> Form
set field value model =
    case field of
        ProjectName ->
            { model | projectName = value }

        ContextName ->
            { model | contextName = value }

        Text ->
            { model | todoText = value }

        Date ->
            { model | date = value }

        Time ->
            { model | time = value }
