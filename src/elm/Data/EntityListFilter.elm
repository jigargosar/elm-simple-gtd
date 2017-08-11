module Data.EntityListFilter
    exposing
        ( Filter(..)
        , FilterViewModel
        , FlatFilterType(..)
        , GroupByType(..)
        , Path
        , contextFilter
        , groupByActiveContextsFilter
        , initialFilterPathTuple
        , maybeFromPath
        , projectFilter
        , toPath
        , toViewModel
        )

--import X.List as List

import Color exposing (Color)
import Colors exposing (..)
import Document exposing (DocId)
import GroupDoc exposing (GroupDocId, GroupDocType(..))
import IconNames


-- Named Filters


type alias FilterViewModel =
    { displayName : String
    , iconName : String
    , headerColor : Color
    }


type alias Path =
    List String



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


initialFilterPath =
    "contexts" :: []


initialFilter =
    groupByActiveContextsFilter


initialFilterPathTuple =
    ( initialFilter, initialFilterPath )


fromPath : List String -> Filter
fromPath path =
    case path of
        "context" :: [] ->
            inboxFilter

        "context" :: contextDocId :: [] ->
            contextFilter contextDocId

        "inbox" :: [] ->
            inboxFilter

        "contexts" :: [] ->
            groupByActiveContextsFilter

        "project" :: [] ->
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


toPath filter =
    case filter of
        FlatFilter flatFilterType maxDisplayCount ->
            case flatFilterType of
                Done ->
                    [ "done" ]

                Recent ->
                    [ "recent" ]

                Bin ->
                    [ "bin" ]

        GroupByGroupDocFilter gdType groupByType ->
            case gdType of
                ContextGroupDocType ->
                    case groupByType of
                        ActiveGroupDocList ->
                            [ "contexts" ]

                        SingleGroupDoc "" ->
                            [ "inbox" ]

                        SingleGroupDoc contextDocId ->
                            [ "context", contextDocId ]

                ProjectGroupDocType ->
                    case groupByType of
                        ActiveGroupDocList ->
                            [ "projects" ]

                        SingleGroupDoc projectDocId ->
                            [ "project", projectDocId ]

        NoFilter ->
            toPath initialFilter


maybeFromPath : Path -> Maybe Filter
maybeFromPath path =
    let
        filter =
            fromPath path
    in
    case filter of
        NoFilter ->
            Nothing

        _ ->
            Just filter


toViewModel : Filter -> FilterViewModel
toViewModel filter =
    case filter of
        FlatFilter flatFilterType maxDisplayCount ->
            case flatFilterType of
                Done ->
                    FilterViewModel
                        "Done"
                        IconNames.done
                        Colors.sgtdBlue

                Recent ->
                    FilterViewModel
                        "Recent"
                        IconNames.recent
                        Colors.sgtdBlue

                Bin ->
                    FilterViewModel
                        "Bin"
                        IconNames.bin
                        Colors.sgtdBlue

        GroupByGroupDocFilter gdType groupByType ->
            case gdType of
                ContextGroupDocType ->
                    case groupByType of
                        ActiveGroupDocList ->
                            FilterViewModel
                                "Contexts"
                                IconNames.contexts
                                Colors.contexts

                        SingleGroupDoc "" ->
                            FilterViewModel
                                "Inbox"
                                IconNames.nullContext
                                Colors.nullContext

                        SingleGroupDoc contextDocId ->
                            FilterViewModel
                                "Context"
                                IconNames.context
                                Colors.defaultContext

                ProjectGroupDocType ->
                    case groupByType of
                        ActiveGroupDocList ->
                            FilterViewModel
                                "Projects"
                                IconNames.projects
                                Colors.projects

                        SingleGroupDoc "" ->
                            FilterViewModel
                                "No Project Assigned"
                                IconNames.nullProject
                                Colors.nullProject

                        SingleGroupDoc projectDocId ->
                            FilterViewModel
                                "Project"
                                IconNames.project
                                Colors.defaultProject

        NoFilter ->
            toViewModel initialFilter
