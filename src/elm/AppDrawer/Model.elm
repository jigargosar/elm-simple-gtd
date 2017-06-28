module AppDrawer.Model exposing (..)

import X.Record exposing (get, over, set, toggle)
import X.Function exposing (..)
import X.Function.Infix exposing (..)
import Json.Decode as D exposing (Decoder)
import Json.Decode.Pipeline as D
import Json.Encode as E


type Msg
    = OnToggleProjectsExpanded
    | OnToggleContextsExpanded
    | OnToggleArchivedContexts
    | OnToggleArchivedProjects
    | OnToggleOverlay


type alias GroupModel =
    { expanded : Bool
    , showArchived : Bool
    }


defaultGroupModel : GroupModel
defaultGroupModel =
    { expanded = True, showArchived = False }


expanded =
    X.Record.bool .expanded (\s b -> { b | expanded = s })


showArchived =
    X.Record.bool .showArchived (\s b -> { b | showArchived = s })


( groupModelDecoder, groupModelEncoder ) =
    ( D.succeed GroupModel
        |> D.required "expanded" D.bool
        |> D.optional "showArchived" D.bool False
    , \model ->
        E.object
            [ "expanded" => E.bool model.expanded
            , "showArchived" => E.bool model.showArchived
            ]
    )


setArchivedExpandedTo bool =
    set showArchived bool


toggleArchivedExpanded =
    toggle showArchived


isArchivedExpanded =
    get showArchived


toggleExpanded =
    toggle expanded


isExpanded =
    get expanded


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
        [ "contexts" => groupModelEncoder model.contexts
        , "projects" => groupModelEncoder model.projects
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


isOverlayOpen =
    X.Record.bool .isOverlayOpen (\s b -> { b | isOverlayOpen = s })


toggleOverlay =
    toggle isOverlayOpen


hideArchived groupModel =
    over groupModel (setArchivedExpandedTo False)


toggleArchivedForGroup groupField =
    over groupField toggleArchivedExpanded


toggleGroupListExpanded groupField =
    over groupField (toggleExpanded >> unless isExpanded (setArchivedExpandedTo False))


isGroupListExpanded groupField =
    get groupField >> isExpanded


getProjectsExpanded =
    isGroupListExpanded projects


getContextExpanded =
    isGroupListExpanded contexts


isGroupArchivedListExpanded groupField =
    get groupField >> isArchivedExpanded


getArchivedContextsExpanded =
    isGroupArchivedListExpanded contexts


getArchivedProjectsExpanded =
    isGroupArchivedListExpanded projects


toggleGroupArchivedListExpanded groupField =
    over groupField toggleArchivedExpanded
