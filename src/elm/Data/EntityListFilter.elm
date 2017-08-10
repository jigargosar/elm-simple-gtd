module Data.EntityListFilter
    exposing
        ( Filter(..)
        , FlatFilterType(..)
        , GroupByType(..)
        , NamedFilterModel
        , NamedFilterType(..)
        , getMaybeFilterFromPath
        , getNamedFilterModelFromFilter
        , initialFilter
        , namedFilterTypeToModel
        )

--import X.List as List

import Color exposing (Color)
import Colors exposing (..)
import Document exposing (DocId)
import GroupDoc exposing (GroupDocId, GroupDocType(..))
import IconNames
import List.Extra
import Toolkit.Operators exposing (..)
import X.Function exposing (..)


-- Named Filters


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


namedFilterTypeToModel : NamedFilterType -> NamedFilterModel
namedFilterTypeToModel namedFilterType =
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

        NF_GB_ActiveProjects ->
            NamedFilterModel NF_GB_ActiveProjects
                "Projects"
                IconNames.projects
                Colors.projects
                [ "projects" ]
                0

        NF_GB_ActiveContexts ->
            NamedFilterModel NF_WithContextId_GB_Projects
                "Contexts"
                IconNames.contexts
                Colors.contexts
                [ "contexts" ]
                1

        NF_WithProjectId_GB_Contexts ->
            NamedFilterModel NF_WithProjectId_GB_Contexts
                "Project"
                IconNames.project
                Colors.defaultProject
                [ "project" ]
                1

        NF_WithContextId_GB_Projects ->
            NamedFilterModel NF_GB_ActiveContexts
                "Context"
                IconNames.context
                Colors.defaultContext
                [ "context" ]
                0



-- Filters


type FlatFilterType
    = Done
    | Recent
    | Bin


type alias MaxDisplayCount =
    Int


defaultMaxDisplayCount =
    25


type GroupByType
    = ActiveGroupDocList
    | SingleGroupDoc DocId


type Filter
    = FlatFilter FlatFilterType MaxDisplayCount
    | GroupByGroupDocFilter GroupDocType GroupByType
    | NoFilter


initialFilter =
    groupByActiveContextsFilter


groupByActiveContextsFilter =
    GroupByGroupDocFilter ContextGroupDocType ActiveGroupDocList


groupByActiveProjectsFilter =
    GroupByGroupDocFilter ProjectGroupDocType ActiveGroupDocList


inboxFilter =
    contextFilter ""


noProjectFilter =
    projectFilter ""


contextFilter contextDocId =
    GroupByGroupDocFilter ContextGroupDocType (SingleGroupDoc contextDocId)


projectFilter projectDocId =
    GroupByGroupDocFilter ProjectGroupDocType (SingleGroupDoc projectDocId)


flatFilter flatFilterType =
    FlatFilter flatFilterType defaultMaxDisplayCount


getFilterFromPath : List String -> Filter
getFilterFromPath path =
    case path of
        "context" :: [] ->
            inboxFilter

        "context" :: contextDocId :: [] ->
            contextFilter contextDocId

        "inbox" :: [] ->
            inboxFilter

        "contexts" :: [] ->
            groupByActiveContextsFilter

        "project" :: "" :: [] ->
            noProjectFilter

        "project" :: projectDocId :: [] ->
            projectFilter projectDocId

        "projects" :: [] ->
            groupByActiveProjectsFilter

        "no-project" :: [] ->
            noProjectFilter

        "done" :: [] ->
            flatFilter Done

        "recent" :: [] ->
            flatFilter Recent

        "bin" :: [] ->
            flatFilter Bin

        _ ->
            NoFilter


type alias Path =
    List String


getMaybeFilterFromPath : Path -> Maybe Filter
getMaybeFilterFromPath path =
    let
        filter =
            getFilterFromPath path
    in
    case filter of
        NoFilter ->
            Nothing

        _ ->
            Just filter


getNamedFilterModelFromFilter : Filter -> NamedFilterModel
getNamedFilterModelFromFilter filter =
    case filter of
        FlatFilter flatFilterType maxDisplayCount ->
            case flatFilterType of
                Done ->
                    namedFilterTypeToModel NF_FL_Done

                Recent ->
                    namedFilterTypeToModel NF_FL_Recent

                Bin ->
                    namedFilterTypeToModel NF_FL_Bin

        GroupByGroupDocFilter gdType groupByType ->
            case gdType of
                ContextGroupDocType ->
                    case groupByType of
                        ActiveGroupDocList ->
                            namedFilterTypeToModel NF_GB_ActiveContexts

                        SingleGroupDoc "" ->
                            namedFilterTypeToModel NF_WithNullContext

                        SingleGroupDoc contextDocId ->
                            namedFilterTypeToModel NF_WithContextId_GB_Projects

                ProjectGroupDocType ->
                    case groupByType of
                        ActiveGroupDocList ->
                            namedFilterTypeToModel NF_GB_ActiveProjects

                        SingleGroupDoc "" ->
                            namedFilterTypeToModel NF_WithNullProject

                        SingleGroupDoc projectDocId ->
                            namedFilterTypeToModel NF_WithProjectId_GB_Contexts

        NoFilter ->
            namedFilterTypeToModel NF_GB_ActiveContexts


getPathFromFilter filter =
    getNamedFilterModelFromFilter
