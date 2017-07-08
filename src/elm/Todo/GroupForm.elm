module Todo.GroupForm exposing (..)

import Document
import Document.Types exposing (DocId)
import Menu
import Todo
import Todo.Types exposing (TodoDoc)


type alias Model =
    { todo : TodoDoc
    , todoId : DocId
    , contextId : DocId
    , projectId : DocId
    , menuState : Menu.State
    }


init todo =
    { todo = todo
    , todoId = Document.getId todo
    , contextId = Todo.getContextId todo
    , projectId = Todo.getProjectId todo
    , menuState = Menu.initState
    }


setMenuState menuState form =
    { form | menuState = menuState }
