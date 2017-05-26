module Todo.NewForm exposing (..)

import Context
import Document
import Entity
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
    { text : Todo.Text
    , referenceEntity : Entity.Entity
    }


type Field
    = Text
    | ReferenceTodoId


create : Entity.Entity -> Todo.Text -> Model
create referenceEntity text =
    { text = text, referenceEntity = referenceEntity }


getText =
    .text


setText text form =
    { form | text = text }
