module Todo.GroupForm exposing (..)

import Document
import Menu
import Todo


type alias Model =
    { todo : Todo.Model
    , todoId : Document.Id
    , contextId : Document.Id
    , projectId : Document.Id
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
