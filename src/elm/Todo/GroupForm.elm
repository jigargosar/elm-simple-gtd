module Todo.GroupForm exposing (..)

import Document
import Menu
import Todo
import Types


type alias Model =
    { todo : Todo.Model
    , todoId : Types.DocId
    , contextId : Types.DocId
    , projectId : Types.DocId
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
