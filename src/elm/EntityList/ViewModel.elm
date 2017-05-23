module EntityList.ViewModel exposing (..)

import Entity exposing (Entity)
import Model
import Toolkit.Helpers exposing (..)
import Toolkit.Operators exposing (..)
import Ext.Function exposing (..)
import Ext.Function.Infix exposing (..)
import List.Extra as List
import Maybe.Extra as Maybe


type alias ViewModel =
    { entityList : List Entity
    }


create : Entity.ListViewType -> Model.Model -> ViewModel
create viewType model =
    { entityList = Model.createViewEntityList viewType model }
