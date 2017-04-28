module Todo.NewForm exposing (..)

import Context
import Document
import Project
import Toolkit.Helpers exposing (..)
import Toolkit.Operators exposing (..)
import Ext.Function exposing (..)
import Ext.Function.Infix exposing (..)
import List.Extra as List
import Maybe.Extra as Maybe
import Todo


type alias Model =
    { id : Document.Id
    , text : Todo.Text
    , project : Project.Model
    , context : Context.Model
    }


type Action
    = SetText String



--create =
