module Todo.Menu exposing (..)

import Document.Types exposing (DocId)
import Menu
import Menu.Types exposing (MenuState)
import Todo


type alias Model =
    { todoId : DocId
    , menuState : MenuState
    }


init todoId =
    { todoId = todoId, menuState = Menu.initState }


setMenuState menuState form =
    { form | menuState = menuState }
