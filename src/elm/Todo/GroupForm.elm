module Todo.GroupForm exposing (..)

import Document
import Menu
import Todo
import Types


type alias Model =
    { todo : Todo.Model
    , todoId : Types.DocId__
    , contextId : Types.DocId__
    , projectId : Types.DocId__
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
