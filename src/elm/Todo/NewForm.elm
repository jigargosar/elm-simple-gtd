module Todo.NewForm exposing (..)

import Entity
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
