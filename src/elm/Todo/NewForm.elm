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


create : Todo.Model -> Project.Model -> Context.Model -> Model
create todo project context =
    { id = Document.getId todo
    , text = Todo.getText todo
    , project = project
    , context = context
    }


set : Action -> Model -> Model
set action model =
    case action of
        SetText value ->
            { model | text = value }
