module Todo.MoreMenu exposing (..)

import Html
import Menu
import Todo.Menu
import Model
import Msg
import Todo.FormTypes exposing (TodoMoreMenuForm)


type alias MenuItem =
    { type_ : ItemType
    , displayName : String
    }


type ItemType
    = Foo
    | Bar


moreMenuConfig : TodoMoreMenuForm -> Menu.Config String Msg.Msg
moreMenuConfig model =
    { onSelect = (\_ -> Model.noop)
    , isSelected = (\_ -> False)
    , itemKey = identity
    , itemSearchText = identity
    , itemView = Html.text
    , onStateChanged = (\_ -> Model.noop)
    , noOp = Model.noop
    , onOutsideMouseDown = Msg.OnDeactivateEditingMode
    }


view model =
    Menu.view [ "Comming Soon", "Split", "Delete" ]
        model.menuState
        (moreMenuConfig model)
