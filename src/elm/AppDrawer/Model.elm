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
    | OnToggleShowArchivedContexts
    | OnToggleShowArchivedProjects


type alias GroupModel =
    { expanded : Bool
    , showArchived : Bool
    }


groupModelDecoder =
    D.succeed GroupModel
        |> D.required "expanded" D.bool
        |> D.optional "showArchived" D.bool False


encodeGroupModel model =
    E.object
        [ "expanded" => E.bool model.expanded
        , "showArchived" => E.bool model.showArchived
        ]


defaultGroupModel : GroupModel
defaultGroupModel =
    { expanded = True, showArchived = False }


type alias Model =
    { contexts : GroupModel
    , projects : GroupModel
    }


decode =
    D.succeed Model
        |> D.required "contexts" groupModelDecoder
        |> D.required "projects" groupModelDecoder


encode model =
    E.object
        [ "contexts" => encodeGroupModel model.contexts
        , "projects" => encodeGroupModel model.projects
        ]


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


showArchived =
    Ext.Record.bool .showArchived (\s b -> { b | showArchived = s })


toggleExpanded =
    Ext.Record.toggle expanded


toggleShowArchived =
    Ext.Record.toggle showArchived


setShowArchived bool =
    Ext.Record.set showArchived bool


toggleProjectListExpanded =
    Ext.Record.over projects (toggleExpanded)


isProjectListExpanded =
    Ext.Record.get projects >> Ext.Record.get expanded


toggleContextListExpanded =
    Ext.Record.over contexts (toggleExpanded)
        >> (\model ->
                if isContextListExpanded model then
                    model
                else
                    hideArchivedContexts model
           )


isContextListExpanded =
    Ext.Record.get contexts >> Ext.Record.get expanded


getShowArchivedForContexts =
    Ext.Record.get contexts >> Ext.Record.get showArchived


getShowArchivedForProjects =
    Ext.Record.get projects >> Ext.Record.get showArchived


hideArchivedContexts =
    Ext.Record.over contexts (setShowArchived False)


hideArchivedProjects =
    Ext.Record.over projects (setShowArchived False)


toggleContextShowArchived =
    Ext.Record.over contexts (toggleShowArchived)


toggleProjectShowArchived =
    Ext.Record.over projects (toggleShowArchived)
