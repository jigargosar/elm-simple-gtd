module View.MainMenu exposing (..)

import Html
import Menu
import Toolkit.Helpers exposing (..)
import Toolkit.Operators exposing (..)
import X.Function exposing (..)
import X.Function.Infix exposing (..)
import List.Extra as List
import Maybe.Extra as Maybe
import Model


menuConfig : Menu.State -> Model.Model -> Menu.Config String Model.Msg
menuConfig menuState model =
    { onSelect =
        Model.noop
    , isSelected = (\_ -> False)
    , itemKey = identity
    , itemSearchText = identity
    , itemView = Html.text
    , onStateChanged = Model.OnMainMenuStateChanged
    , noOp = Model.noop
    , onOutsideMouseDown = Model.OnDeactivateEditingMode
    }


init menuState appModel =
    Menu.view [ "a", "b" ]
        menuState
        (menuConfig menuState appModel)
