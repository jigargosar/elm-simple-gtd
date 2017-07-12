module Todo.NewForm exposing (..)

import Entity.Types exposing (Entity)
import Todo
import Todo.Form exposing (AddTodoForm)


type Field
    = Text
    | ReferenceTodoId


create : Entity -> Todo.Text -> AddTodoForm
create referenceEntity text =
    { text = text, referenceEntity = referenceEntity }


getText =
    .text


setText text form =
    { form | text = text }
