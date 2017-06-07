module Todo.GroupForm exposing (..)

import Menu
import Todo
import Toolkit.Helpers exposing (..)
import Toolkit.Operators exposing (..)
import Ext.Function exposing (..)
import Ext.Function.Infix exposing (..)
import List.Extra as List
import Maybe.Extra as Maybe


type alias Model =
    { todo : Todo.Model
    , menuState : Menu.State
    }


init todo =
    { todo = todo, menuState = Menu.initState }


setMenuState menuState form =
    { form | menuState = menuState }
