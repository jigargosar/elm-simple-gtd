module Update.MainViewType exposing (..)

import Model.Selection
import Model.ViewType
import Return exposing (map)
import Toolkit.Helpers exposing (..)
import Toolkit.Operators exposing (..)
import X.Function exposing (..)
import X.Function.Infix exposing (..)
import List.Extra as List
import Maybe.Extra as Maybe
import ViewType exposing (ViewTypeMsg(OnSetViewType))


update msg =
    case msg of
        OnSetViewType viewType ->
            map (switchToView viewType >> Model.Selection.clearSelection)


switchToView mainViewType model =
    { model | mainViewType = mainViewType }
