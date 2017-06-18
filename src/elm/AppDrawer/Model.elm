module AppDrawer.Model exposing (..)

import Ext.Record
import Toolkit.Helpers exposing (..)
import Toolkit.Operators exposing (..)
import Ext.Function exposing (..)
import Ext.Function.Infix exposing (..)
import List.Extra as List
import Maybe.Extra as Maybe
import Json.Decode as D exposing (Decoder)
import Json.Decode.Pipeline as D
import Json.Encode as E


type Msg
    = OnToggleExpandProjectList
    | OnToggleExpandContextList


type alias GroupModel =
    { expanded : Bool
    }


groupModelDecoder =
    D.succeed GroupModel
        |> D.required "expanded" D.bool


defaultGroupModel : GroupModel
defaultGroupModel =
    { expanded = True }


type alias Model =
    { contexts : GroupModel
    , projects : GroupModel
    }


decode =
    D.succeed Model
        |> D.required "contexts" groupModelDecoder
        |> D.required "projects" groupModelDecoder


default : Model
default =
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


isProjectListExpanded =
    Ext.Record.get projects >> Ext.Record.get expanded


toggleContextListExpanded =
    Ext.Record.over contexts (toggleExpanded)


isContextListExpanded =
    Ext.Record.get contexts >> Ext.Record.get expanded
