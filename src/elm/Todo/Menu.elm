module Todo.Menu exposing (..)

import Menu
import Todo


type alias Model =
    { todoId : Todo.Id
    , menuState : Menu.State
    }


init todoId =
    { todoId = todoId, menuState = Menu.initState }


setMenuState menuState form =
    { form | menuState = menuState }
