module ReturnTypes exposing (..)

import Entity.Types exposing (EntityListViewType(ContextsView))
import Msg exposing (AppMsg)
import Return
import Types exposing (AppModel)
import ViewType exposing (ViewType(EntityListView))


type alias Return =
    Return.Return AppMsg AppModel


type alias ModelReturnF =
    AppModel -> Return


type alias ReturnF =
    Return.ReturnF AppMsg AppModel


type alias AndThenUpdate =
    AppMsg -> ReturnF


type alias ModelF =
    AppModel -> AppModel



-- todo: move to viewUpdate file.


defaultView =
    EntityListView ContextsView


type alias Subscriptions =
    AppModel -> Sub AppMsg