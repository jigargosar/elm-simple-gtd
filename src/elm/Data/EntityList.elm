module Data.EntityList exposing (..)

--import X.List as List

import Color exposing (Color)
import Colors exposing (..)
import IconNames
import List.Extra as List
import Maybe.Extra as Maybe
import Toolkit.Helpers exposing (..)
import Toolkit.Operators exposing (..)
import X.Function exposing (..)
import X.Function.Infix exposing (..)


type NamedFilterType
    = NF_WithNullContext
    | NF_WithNullProject
    | NF_FL_Done
    | NF_FL_Recent
    | NF_FL_Bin
    | NF_GB_ActiveContexts
    | NF_GB_ActiveProjects
    | NF_WithContextId_GB_Projects
    | NF_WithProjectId_GB_Contexts


type alias NamedFilterModel =
    { namedFilterType : NamedFilterType
    , displayName : String
    , iconName : String
    , headerColor : Color
    , pathPrefix : List String
    , pathArgumentsCount : Int
    }


namedFilterTypeList =
    [ NF_WithNullContext
    , NF_WithNullProject
    , NF_FL_Done
    , NF_FL_Recent
    , NF_FL_Bin
    , NF_GB_ActiveContexts
    , NF_GB_ActiveProjects
    , NF_WithContextId_GB_Projects
    , NF_WithProjectId_GB_Contexts
    ]


type2Model namedFilterType =
    case namedFilterType of
        NF_WithNullContext ->
            NamedFilterModel NF_WithNullContext
                "Inbox"
                IconNames.nullContext
                Colors.nullContext
                [ "context" ]
                0

        NF_WithNullProject ->
            NamedFilterModel NF_WithNullProject
                "No Project Assigned"
                IconNames.nullProject
                Colors.nullProject
                [ "project" ]
                0

        NF_FL_Done ->
            NamedFilterModel NF_FL_Done
                "Done"
                IconNames.done
                Colors.sgtdBlue
                [ "done" ]
                0

        NF_FL_Recent ->
            NamedFilterModel NF_FL_Recent
                "Recent"
                IconNames.recent
                Colors.sgtdBlue
                [ "recent" ]
                0

        NF_FL_Bin ->
            NamedFilterModel NF_FL_Bin
                "Bin"
                IconNames.bin
                Colors.sgtdBlue
                [ "bin" ]
                0

        NF_GB_ActiveContexts ->
            NamedFilterModel NF_GB_ActiveProjects
                "Projects"
                IconNames.projects
                Colors.projects
                [ "projects" ]
                0

        NF_GB_ActiveProjects ->
            NamedFilterModel NF_WithContextId_GB_Projects
                "Context"
                IconNames.context
                Colors.defaultContext
                [ "context" ]
                1

        NF_WithContextId_GB_Projects ->
            NamedFilterModel NF_WithProjectId_GB_Contexts
                "Project"
                IconNames.project
                Colors.defaultProject
                [ "project" ]
                1

        NF_WithProjectId_GB_Contexts ->
            NamedFilterModel NF_GB_ActiveContexts
                "Contexts"
                IconNames.contexts
                Colors.contexts
                [ "contexts" ]
                0


namedFilterList =
    [ NamedFilterModel NF_WithNullContext
        "Inbox"
        IconNames.nullContext
        Colors.nullContext
        [ "context" ]
        0
    , NamedFilterModel NF_WithNullProject
        "No Project Assigned"
        IconNames.nullProject
        Colors.nullProject
        [ "project" ]
        0
    , NamedFilterModel NF_FL_Done
        "Done"
        IconNames.done
        Colors.sgtdBlue
        [ "done" ]
        0
    , NamedFilterModel NF_FL_Recent
        "Recent"
        IconNames.recent
        Colors.sgtdBlue
        [ "recent" ]
        0
    , NamedFilterModel NF_FL_Bin
        "Bin"
        IconNames.bin
        Colors.sgtdBlue
        [ "bin" ]
        0
    , NamedFilterModel NF_GB_ActiveProjects
        "Projects"
        IconNames.projects
        Colors.projects
        [ "projects" ]
        0
    , NamedFilterModel NF_WithContextId_GB_Projects
        "Context"
        IconNames.context
        Colors.defaultContext
        [ "context" ]
        1
    , NamedFilterModel NF_WithProjectId_GB_Contexts
        "Project"
        IconNames.project
        Colors.defaultProject
        [ "project" ]
        1
    ]
        |> (::) activeContextsNamedFilter


activeContextsNamedFilter =
    NamedFilterModel NF_GB_ActiveContexts
        "Contexts"
        IconNames.contexts
        Colors.contexts
        [ "contexts" ]
        0


uncurryNamedFilterModelFrom =
    \( namedFilterType, displayName, iconName, headerColor, pathPrefix, pathArgumentsCount ) ->
        NamedFilterModel namedFilterType displayName iconName headerColor pathPrefix pathArgumentsCount


getMaybeNamedFilterModelFromPath : List String -> Maybe NamedFilterModel
getMaybeNamedFilterModelFromPath path =
    let
        matchesPath model =
            path
                |> List.reverse
                |> List.drop model.pathArgumentsCount
                |> equals (List.reverse model.pathPrefix)
    in
    List.find matchesPath namedFilterList


getMaybeNamedFilterModelFromType namedFilterType =
    let
        matchesFilterType model =
            model.namedFilterType == namedFilterType
    in
    List.find matchesFilterType namedFilterList


getMaybeTitleColourTuple namedFilterType =
    getMaybeNamedFilterModelFromType namedFilterType
        ?|> (\model -> ( model.displayName, model.headerColor ))
