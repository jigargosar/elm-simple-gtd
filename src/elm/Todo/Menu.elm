module Todo.Menu exposing (..)

import Menu
import Todo
import Types


type alias Model =
    { todoId : Types.DocId__
    , menuState : Menu.State
    }


init todoId =
    { todoId = todoId, menuState = Menu.initState }


setMenuState menuState form =
    { form | menuState = menuState }
