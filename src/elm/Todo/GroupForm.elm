module Todo.GroupForm exposing (..)

import Menu
import Todo








type alias Model =
    { todo : Todo.Model
    , menuState : Menu.State
    }


init todo =
    { todo = todo, menuState = Menu.initState }


setMenuState menuState form =
    { form | menuState = menuState }
