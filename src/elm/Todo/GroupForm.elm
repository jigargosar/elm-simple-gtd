module Todo.GroupForm exposing (..)

import Document
import Document.Types exposing (DocId, getDocId)
import Menu
import Menu.Types exposing (MenuState)
import Todo
import Todo.Types exposing (TodoDoc)


type alias Model =
    { todo : TodoDoc
    , todoId : DocId
    , contextId : DocId
    , projectId : DocId
    , menuState : MenuState
    }


init todo =
    { todo = todo
    , todoId = getDocId todo
    , contextId = Todo.getContextId todo
    , projectId = Todo.getProjectId todo
    , menuState = Menu.initState
    }


setMenuState menuState form =
    { form | menuState = menuState }
