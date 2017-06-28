module AppDrawer.Model exposing (..)

import X.Record exposing (get, over, set)
import X.Function exposing (..)
import X.Function.Infix exposing (..)
import Json.Decode as D exposing (Decoder)
import Json.Decode.Pipeline as D
import Json.Encode as E


type Msg
    = OnToggleProjects
    | OnToggleContexts
    | OnToggleArchivedContexts
    | OnToggleArchivedProjects
    | OnToggleOverlay


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
    , isOverlayOpen : Bool
    }


defaultIsOverlayOpen =
    False


decode =
    D.succeed Model
        |> D.required "contexts" groupModelDecoder
        |> D.required "projects" groupModelDecoder
        |> D.optional "isOverlayOpen" D.bool defaultIsOverlayOpen


encode model =
    E.object
        [ "contexts" => encodeGroupModel model.contexts
        , "projects" => encodeGroupModel model.projects
        , "isOverlayOpen" => E.bool model.isOverlayOpen
        ]


default : Model
default =
    { contexts = defaultGroupModel
    , projects = defaultGroupModel
    , isOverlayOpen = defaultIsOverlayOpen
    }


contexts =
    X.Record.field .contexts (\s b -> { b | contexts = s })


projects =
    X.Record.field .projects (\s b -> { b | projects = s })


expanded =
    X.Record.bool .expanded (\s b -> { b | expanded = s })


showArchived =
    X.Record.bool .showArchived (\s b -> { b | showArchived = s })


isOverlayOpen =
    X.Record.bool .isOverlayOpen (\s b -> { b | isOverlayOpen = s })


toggleOverlay =
    X.Record.toggle isOverlayOpen


toggleExpanded =
    X.Record.toggle expanded


toggleArchivedExpanded =
    X.Record.toggle showArchived


setArchivedExpandedTo bool =
    set showArchived bool


hideArchived groupModel =
    over groupModel (setArchivedExpandedTo False)


toggleArchivedForGroup groupField =
    over groupField toggleArchivedExpanded


toggleGroupField groupField =
    over groupField (toggleExpanded >> unless (get expanded) (setArchivedExpandedTo False))


isGroupExpanded groupField =
    get groupField >> get expanded


toggleProjects =
    toggleGroupField projects


toggleContexts =
    toggleGroupField contexts


getProjectsExpanded =
    isGroupExpanded projects


getContextExpanded =
    isGroupExpanded contexts


getArchivedContextsExpanded =
    get contexts >> get showArchived


getArchivedProjectsExpanded =
    get projects >> get showArchived


toggleArchivedContexts =
    over contexts (toggleArchivedExpanded)


toggleArchivedProjects =
    over projects (toggleArchivedExpanded)
