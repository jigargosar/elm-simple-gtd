module Todo.NewForm exposing (..)

import Entity.Types exposing (EntityType)
import Todo
import Todo.FormTypes exposing (AddTodoForm)


type Field
    = Text
    | ReferenceTodoId


create : EntityType -> Todo.Text -> AddTodoForm
create referenceEntity text =
    { text = text, referenceEntity = referenceEntity }


getText =
    .text


setText text form =
    { form | text = text }
