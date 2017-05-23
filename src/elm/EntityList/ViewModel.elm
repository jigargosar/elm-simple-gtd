module EntityList.ViewModel exposing (..)

import Model
import Toolkit.Helpers exposing (..)
import Toolkit.Operators exposing (..)
import Ext.Function exposing (..)
import Ext.Function.Infix exposing (..)
import List.Extra as List
import Maybe.Extra as Maybe


create viewType model =
    { entityList = Model.createViewEntityList viewType model }
