module AppDrawer.Model exposing (..)

import Ext.Record
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


defaultGroupModel : GroupModel
defaultGroupModel =
    { expanded = True }


type alias Model =
    { contexts : GroupModel
    , projects : GroupModel
    }


init : Model
init =
    { contexts = defaultGroupModel
    , projects = defaultGroupModel
    }


contexts =
    Ext.Record.field .contexts (\s b -> { b | contexts = s })


projects =
    Ext.Record.field .projects (\s b -> { b | projects = s })


expanded =
    Ext.Record.bool .expanded (\s b -> { b | expanded = s })


toggleExpanded =
    Ext.Record.toggle expanded


toggleProjectListExpanded =
    Ext.Record.over projects (toggleExpanded)
