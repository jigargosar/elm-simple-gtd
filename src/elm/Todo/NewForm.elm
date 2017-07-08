module Todo.NewForm exposing (..)

import Entity
import Entity.Types exposing (EntityType)
import Todo


type alias Model =
    { text : Todo.Text
    , referenceEntity : EntityType
    }


type Field
    = Text
    | ReferenceTodoId


create : EntityType -> Todo.Text -> Model
create referenceEntity text =
    { text = text, referenceEntity = referenceEntity }


getText =
    .text


setText text form =
    { form | text = text }
