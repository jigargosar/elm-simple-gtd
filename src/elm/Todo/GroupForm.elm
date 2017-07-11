module Todo.GroupForm exposing (..)

import Document.Types exposing (DocId, getDocId)
import Menu
import Todo


init todo =
    { todoId = getDocId todo
    , contextId = Todo.getContextId todo
    , projectId = Todo.getProjectId todo
    , menuState = Menu.initState
    }


setMenuState menuState form =
    { form | menuState = menuState }
