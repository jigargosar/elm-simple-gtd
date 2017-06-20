module Todo.MoreMenu exposing (..)

import Html
import Menu
import Todo.Menu
import Toolkit.Helpers exposing (..)
import Toolkit.Operators exposing (..)
import Ext.Function exposing (..)
import Ext.Function.Infix exposing (..)
import List.Extra as List
import Maybe.Extra as Maybe
import Model


type alias MenuItem =
    { type_ : ItemType
    , displayName : String
    }


type ItemType
    = Foo
    | Bar


moreMenuConfig : Todo.Menu.Model -> Menu.Config String Model.Msg
moreMenuConfig model =
    { onSelect = (\_ -> Model.NOOP)
    , isSelected = (\_ -> False)
    , itemKey = identity
    , itemSearchText = identity
    , itemView = Html.text
    , onStateChanged = (\_ -> Model.NOOP)
    , noOp = Model.NOOP
    , onOutsideMouseDown = Model.OnDeactivateEditingMode
    }


view model =
    Menu.view [ "foo", "bar" ]
        model.menuState
        (moreMenuConfig model)
