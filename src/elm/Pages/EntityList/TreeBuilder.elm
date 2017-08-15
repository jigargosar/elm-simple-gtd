module Pages.EntityList.TreeBuilder exposing (..)

import Data.EntityListFilter as Filter exposing (Filter(..), FilterViewModel, FlatFilterType(..), GroupByType(..), Path)
import Data.EntityTree as Tree exposing (GroupDocEntityNode(..), Tree)
import Data.TodoDoc as TodoDoc exposing (TodoDoc)
import Date
import Date.Extra
import Dict exposing (Dict)
import Dict.Extra
import Document exposing (..)
import Entity exposing (..)
import GroupDoc exposing (..)
import List.Extra
import Models.GroupDocStore as GroupDocStore
import Models.Stores
import Models.TodoDocStore as TodoDocStore
import Store
import Time exposing (Time)
import Toolkit.Helpers exposing (..)
import Toolkit.Operators exposing (..)
import X.Function.Infix exposing (..)
import X.Predicate


filterTodosAndSortBy pred sortBy model =
    TodoDocStore.filterTodoDocs pred model
        |> List.sortBy sortBy


filterTodosAndSortByLatestCreated pred =
    filterTodosAndSortBy pred (TodoDoc.getCreatedAt >> negate)


filterTodosAndSortByLatestModified pred =
    filterTodosAndSortBy pred (TodoDoc.getModifiedAt >> negate)


activeTodoListPredicateForGroupDocId groupDocId =
    X.Predicate.all
        [ TodoDoc.isActive
        , TodoDoc.hasGroupDocId groupDocId
        ]


getActiveTodoListForGroupDoc gdType groupDoc appModel =
    let
        secondaryGDType =
            computeSecondaryGroupDocType gdType

        groupDocId =
            GroupDoc.idFromDoc gdType groupDoc

        activeSecondaryGroupDocIdSet =
            GroupDocStore.getActiveDocIdSet secondaryGDType appModel

        isTodoSecondaryGroupDocActive =
            TodoDoc.hasGroupDocIdInSet secondaryGDType activeSecondaryGroupDocIdSet

        pred =
            X.Predicate.all
                [ activeTodoListPredicateForGroupDocId groupDocId
                , isTodoSecondaryGroupDocActive
                ]
    in
    filterTodosAndSortByLatestCreated pred appModel


computeSecondaryGroupDocType gdType =
    case gdType of
        ContextGroupDocType ->
            ProjectGroupDocType

        ProjectGroupDocType ->
            ContextGroupDocType


getActiveTodoListForGroupDocEntity (GroupDocEntity gdType groupDoc) =
    getActiveTodoListForGroupDoc gdType groupDoc


createActiveGroupDocForest gdType appModel =
    let
        activeGroupDocEntityList =
            GroupDocStore.getActiveDocs gdType appModel
                .|> Entity.createGroupDocEntity gdType

        createNode : GroupDocEntity -> GroupDocEntityNode
        createNode groupDocEntity =
            let
                todoList =
                    getActiveTodoListForGroupDocEntity groupDocEntity appModel
            in
            Tree.createGroupDocEntityNode groupDocEntity
                todoList
    in
    activeGroupDocEntityList
        .|> createNode
        |> Tree.createForest


createGroupDocTree gdType docId appModel =
    let
        gDoc =
            let
                groupDocId =
                    GroupDoc.createId gdType docId
            in
            GroupDocStore.findByGroupDocIdOrNull groupDocId appModel

        groupDocEntity =
            Entity.createGroupDocEntity gdType gDoc

        todoList =
            getActiveTodoListForGroupDocEntity groupDocEntity appModel

        secondaryGDType =
            computeSecondaryGroupDocType gdType

        todoListToUniqueGroupDocIdList : GroupDocType -> List TodoDoc -> List GroupDocId
        todoListToUniqueGroupDocIdList gdType todoList =
            todoList
                .|> TodoDoc.getGroupDocId gdType
                |> List.Extra.uniqueBy GroupDoc.toComparable

        secondaryGDList =
            let
                isNull =
                    GroupDoc.isNull secondaryGDType

                findByGroupDocId groupDocId =
                    GroupDocStore.findByGroupDocId groupDocId appModel
            in
            todoList
                |> todoListToUniqueGroupDocIdList secondaryGDType
                .|> findByGroupDocId
                |> List.filterMap identity
                |> GroupDoc.sortWithIsNull isNull

        nodeList =
            let
                idFromDoc doc =
                    GroupDoc.idFromDoc secondaryGDType doc

                createEntity gDoc =
                    Entity.createGroupDocEntity secondaryGDType gDoc

                filterTodoList gDoc =
                    List.filter (TodoDoc.hasGroupDocId (idFromDoc gDoc)) todoList

                createGroupDocEntityNode gDoc =
                    Tree.createGroupDocEntityNode
                        (createEntity gDoc)
                        (filterTodoList gDoc)
            in
            secondaryGDList .|> createGroupDocEntityNode
    in
    Tree.createGroupDocTree groupDocEntity todoList nodeList


flatFilterTypeToPredicate filterType =
    case filterType of
        Done ->
            X.Predicate.all [ Document.isNotDeleted, TodoDoc.isDone ]

        Recent ->
            X.Predicate.always

        Bin ->
            Document.isDeleted


scheduleGroupNames =
    [ "Overdue", "Later" ]


type ScheduleGroup
    = OverDue
    | Later


type alias ScheduleGroupModel =
    { name : String
    , filter : Time -> Time -> Bool
    }


laterScheduleGroupModel =
    ScheduleGroupModel "Later" (\now scheduleTime -> True)


todayScheduleGroupModel =
    ScheduleGroupModel "Today"
        (\now scheduleTime ->
            Date.Extra.equalBy Date.Extra.Day
                (Date.fromTime now)
                (Date.fromTime scheduleTime)
        )


tomorrowScheduleGroupModel =
    ScheduleGroupModel "Tomorrow"
        (\now scheduleTime ->
            Date.Extra.equalBy Date.Extra.Day
                (Date.fromTime now |> Date.Extra.add Date.Extra.Day 1)
                (Date.fromTime scheduleTime)
        )


scheduleGroupModelList =
    [ ScheduleGroupModel "Overdue" (\now scheduleTime -> scheduleTime < now)
    , todayScheduleGroupModel
    , tomorrowScheduleGroupModel
    , laterScheduleGroupModel
    ]


toScheduleTitleString now todo =
    let
        scheduleTime =
            TodoDoc.getMaybeTime todo ?= 0

        { name } =
            scheduleGroupModelList
                |> List.Extra.find (\{ filter } -> filter now scheduleTime)
                ?= laterScheduleGroupModel
    in
    name


createEntityTree filter title appModel =
    case filter of
        GroupByGroupDocFilter gdType groupByType ->
            case groupByType of
                ActiveGroupDocList ->
                    createActiveGroupDocForest gdType appModel

                SingleGroupDoc docId ->
                    createGroupDocTree gdType docId appModel

        FlatFilter flatFilterType maxDisplayCount ->
            let
                pred =
                    flatFilterTypeToPredicate flatFilterType

                todoList =
                    filterTodosAndSortByLatestModified pred appModel

                totalCount =
                    List.length todoList

                truncatedTodoList =
                    List.take maxDisplayCount todoList
            in
            Tree.createTodoList title
                truncatedTodoList
                totalCount

        ScheduledFilter ->
            let
                scheduledTodoPredicate =
                    X.Predicate.all
                        [ TodoDoc.isScheduled
                        , Models.Stores.allTodoGroupDocActivePredicate appModel
                        ]

                scheduledTodoList =
                    TodoDocStore.filterTodoDocs scheduledTodoPredicate appModel
                        |> List.sortBy (TodoDoc.getMaybeTime >>?= 0)

                scheduleTitleToTodoListDict : Dict String (List TodoDoc)
                scheduleTitleToTodoListDict =
                    scheduledTodoList
                        |> Dict.Extra.groupBy
                            (toScheduleTitleString appModel.lastKnownCurrentTime)

                nodeList =
                    scheduleGroupModelList
                        .|> (\{ name } ->
                                scheduleTitleToTodoListDict
                                    |> Dict.get name
                                    ?= []
                                    |> (\todoList ->
                                            Tree.createTodoListNode name todoList 0
                                       )
                            )
            in
            Tree.createTodoListForest nodeList

        NoFilter ->
            Tree.createForest []
