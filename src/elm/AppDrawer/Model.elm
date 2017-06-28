module AppDrawer.Model exposing (..)

import X.Record
import X.Function exposing (..)
import X.Function.Infix exposing (..)
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


toggleExpanded =
    X.Record.toggle expanded


toggleShowArchived =
    X.Record.toggle showArchived


setShowArchived bool =
    X.Record.set showArchived bool


hideArchived groupModel =
    X.Record.over groupModel (setShowArchived False)


toggleProjectListExpanded =
    X.Record.over projects (toggleExpanded)
        >> unless isProjectListExpanded (hideArchived projects)


toggleContextListExpanded =
    X.Record.over contexts (toggleExpanded)
        >> unless isContextListExpanded (hideArchived contexts)


isProjectListExpanded =
    X.Record.get projects >> X.Record.get expanded


isContextListExpanded =
    X.Record.get contexts >> X.Record.get expanded


getShowArchivedForContexts =
    X.Record.get contexts >> X.Record.get showArchived


getShowArchivedForProjects =
    X.Record.get projects >> X.Record.get showArchived


toggleContextShowArchived =
    X.Record.over contexts (toggleShowArchived)


toggleProjectShowArchived =
    X.Record.over projects (toggleShowArchived)
