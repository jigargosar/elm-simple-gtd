module Todo.Menu exposing (..)

import Menu


init todoId =
    { todoId = todoId, menuState = Menu.initState }


setMenuState menuState form =
    { form | menuState = menuState }
