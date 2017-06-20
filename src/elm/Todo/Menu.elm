module Todo.Menu exposing (..)

import Html
import Menu
import Todo
import Toolkit.Helpers exposing (..)
import Toolkit.Operators exposing (..)
import Ext.Function exposing (..)
import Ext.Function.Infix exposing (..)
import List.Extra as List
import Maybe.Extra as Maybe


type alias Model =
    { taskId : Todo.Id
    , menuState : Menu.State
    }


init taskId =
    { taskId = taskId, menuState = Menu.initState }


setMenuState menuState form =
    { form | menuState = menuState }
