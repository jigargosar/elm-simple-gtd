module AppDrawer.Model exposing (..)

import Json.Decode as D
import Json.Decode.Pipeline as D
import Json.Encode as E
import Toolkit.Helpers exposing (..)
import Toolkit.Operators exposing (..)
import X.Function exposing (..)
import X.Function.Infix exposing (..)
import X.Record exposing (get, over, set, toggle)


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


type alias AppDrawerModel =
    { contexts : GroupModel
    , projects : GroupModel
    , isOverlayOpen : Bool
    }


defaultIsOverlayOpen =
    False


decoder =
    D.succeed AppDrawerModel
        |> D.required "contexts" groupModelDecoder
        |> D.required "projects" groupModelDecoder
        |> D.optional "isOverlayOpen" D.bool defaultIsOverlayOpen


encode model =
    E.object
        [ "contexts" => groupModelEncoder model.contexts
        , "projects" => groupModelEncoder model.projects
        , "isOverlayOpen" => E.bool model.isOverlayOpen
        ]


initialValue initialOfflineStore =
    D.decodeValue (D.field "appDrawerPref" decoder) initialOfflineStore
        != defaultValue


defaultValue : AppDrawerModel
defaultValue =
    { contexts = defaultGroupModel
    , projects = defaultGroupModel
    , isOverlayOpen = defaultIsOverlayOpen
    }


getOfflineStoreKeyValue =
    encode >> tuple2 "appDrawerPref"


contexts =
    X.Record.fieldLens .contexts (\s b -> { b | contexts = s })


projects =
    X.Record.fieldLens .projects (\s b -> { b | projects = s })



--


isOverlayOpen =
    X.Record.bool .isOverlayOpen (\s b -> { b | isOverlayOpen = s })


toggleOverlay =
    toggle isOverlayOpen


getIsOverlayOpen =
    get isOverlayOpen



--


isGroupListExpanded groupField =
    get groupField >> isExpanded


getProjectsExpanded =
    isGroupListExpanded projects


getContextExpanded =
    isGroupListExpanded contexts


toggleGroupListExpanded groupField =
    over groupField (toggleExpanded >> unless isExpanded (setArchivedExpandedTo False))



--


isGroupArchivedListExpanded groupField =
    get groupField >> isArchivedExpanded


getArchivedContextsExpanded =
    isGroupArchivedListExpanded contexts


getArchivedProjectsExpanded =
    isGroupArchivedListExpanded projects


toggleGroupArchivedListExpanded groupField =
    over groupField toggleArchivedExpanded
