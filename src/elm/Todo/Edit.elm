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


type alias Model =
    { id : Document.Id
    , todoText : Todo.Text
    , projectName : Project.Name
    , contextName : Context.Name
    , dueAt : Maybe Time
    , dateInputValue : String
    , timeInputValue : String
    }


create : Todo.Model -> Project.Name -> Context.Name -> Model
create todo projectName contextName =
    let
        dueAt =
            Todo.getDueAt todo
    in
        { id = Document.getId todo
        , todoText = Todo.getText todo
        , dueAt = Todo.getDueAt todo
        , projectName = projectName
        , contextName = contextName
        , dateInputValue = dueAt ?|> (Time.Format.format "%Y-%m-%d") ?= ""
        , timeInputValue = dueAt ?|> (Time.Format.format "%H:%M") ?= ""
        }


setProjectName projectName editTodoModel =
    { editTodoModel | projectName = projectName }


setContextName contextName editTodoModel =
    { editTodoModel | contextName = contextName }


setText text editTodoModel =
    { editTodoModel | todoText = text }
