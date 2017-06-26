module Todo.Menu exposing (..)

import Menu
import Todo


type alias Model =
    { taskId : Todo.Id
    , menuState : Menu.State
    }


init taskId =
    { taskId = taskId, menuState = Menu.initState }


setMenuState menuState form =
    { form | menuState = menuState }
