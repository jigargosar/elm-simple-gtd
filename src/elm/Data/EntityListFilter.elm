module Data.EntityListFilter
    exposing
        ( Filter(..)
        , FlatFilterType(..)
        , GroupByType(..)
        , NamedFilterModel
        , NamedFilterType(..)
        , getFilterFromNamedFilterTypeAndPath
        , getMaybeNamedFilterModelFromPath
        , initialNamedFilterModel
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


namedFilterTypeList : List NamedFilterType
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


initialNamedFilterModel =
    namedFilterTypeToModel NF_GB_ActiveContexts


namedFilterModelList =
    namedFilterTypeList .|> namedFilterTypeToModel


getMaybeNamedFilterModelFromPath : List String -> Maybe NamedFilterModel
getMaybeNamedFilterModelFromPath path =
    let
        matchesPath model =
            path
                |> List.reverse
                |> List.drop model.pathArgumentsCount
                |> equals (List.reverse model.pathPrefix)
    in
    List.Extra.find matchesPath namedFilterModelList



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
    = ActiveGroupDocList GroupDocType
    | SingleGroupDoc GroupDocType DocId


type Filter
    = FlatFilter FlatFilterType MaxDisplayCount
    | GroupByFilter GroupByType
    | NoFilter


getFilterFromNamedFilterTypeAndPath namedFilterType path =
    case namedFilterType of
        NF_WithNullContext ->
            getFilterFromNamedFilterTypeAndPath NF_WithContextId_GB_Projects [ "" ]

        NF_WithNullProject ->
            getFilterFromNamedFilterTypeAndPath NF_WithProjectId_GB_Contexts [ "" ]

        NF_FL_Done ->
            FlatFilter Done defaultMaxDisplayCount

        NF_FL_Recent ->
            FlatFilter Recent defaultMaxDisplayCount

        NF_FL_Bin ->
            FlatFilter Bin defaultMaxDisplayCount

        NF_GB_ActiveContexts ->
            GroupByFilter (ActiveGroupDocList ContextGroupDocType)

        NF_GB_ActiveProjects ->
            GroupByFilter (ActiveGroupDocList ProjectGroupDocType)

        NF_WithContextId_GB_Projects ->
            -- ContextIdFilter (List.Extra.last path ?= "")
            GroupByFilter (SingleGroupDoc ContextGroupDocType (List.Extra.last path ?= ""))

        NF_WithProjectId_GB_Contexts ->
            --ProjectIdFilter (List.Extra.last path ?= "")
            GroupByFilter (SingleGroupDoc ProjectGroupDocType (List.Extra.last path ?= ""))


inboxFilter =
    contextFilter ""


noProjectFilter =
    projectFilter ""


contextFilter contextDocId =
    GroupByFilter (SingleGroupDoc ContextGroupDocType contextDocId)


projectFilter projectDocId =
    GroupByFilter (SingleGroupDoc ProjectGroupDocType projectDocId)


flatFilter flatFilterType =
    FlatFilter flatFilterType defaultMaxDisplayCount


getFilterFromPath : List String -> Filter
getFilterFromPath path =
    case path of
        "context" :: "" :: [] ->
            inboxFilter

        "context" :: contextDocId :: [] ->
            contextFilter contextDocId

        "inbox" :: [] ->
            inboxFilter

        "contexts" :: [] ->
            GroupByFilter (ActiveGroupDocList ContextGroupDocType)

        "project" :: "" :: [] ->
            noProjectFilter

        "project" :: projectDocId :: [] ->
            projectFilter projectDocId

        "projects" :: [] ->
            GroupByFilter (ActiveGroupDocList ProjectGroupDocType)

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

        GroupByFilter groupByType ->
            case groupByType of
                ActiveGroupDocList ContextGroupDocType ->
                    namedFilterTypeToModel NF_GB_ActiveContexts

                ActiveGroupDocList ProjectGroupDocType ->
                    namedFilterTypeToModel NF_GB_ActiveProjects

                SingleGroupDoc ProjectGroupDocType projectDocId ->
                    namedFilterTypeToModel NF_WithProjectId_GB_Contexts

                SingleGroupDoc ContextGroupDocType contextDocId ->
                    namedFilterTypeToModel NF_WithProjectId_GB_Contexts

        NoFilter ->
            namedFilterTypeToModel NF_GB_ActiveContexts
