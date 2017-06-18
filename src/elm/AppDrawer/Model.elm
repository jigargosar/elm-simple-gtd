module AppDrawer.Model exposing (..)

import Toolkit.Helpers exposing (..)
import Toolkit.Operators exposing (..)
import Ext.Function exposing (..)
import Ext.Function.Infix exposing (..)
import List.Extra as List
import Maybe.Extra as Maybe


type Msg
    = OnToggleExpandProjectList
    | OnToggleExpandContextList


type alias GroupModel =
    { expanded : Bool
    }


type alias Model =
    { contexts : GroupModel
    , projects : GroupModel
    }
