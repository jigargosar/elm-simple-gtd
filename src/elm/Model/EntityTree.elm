module Model.EntityTree exposing (..)

import Context
import Document
import Document.Types exposing (DeviceId, DocId, getDocId)
import Entity
import Entity.Tree
import Entity.Types exposing (..)
import EntityId
import GroupDoc
import GroupDoc.Types exposing (ContextStore, GroupDoc, ProjectStore)
import Model.GroupDocStore exposing (..)
import Model.Stores
import Model.TodoStore exposing (..)
import Msg exposing (AppMsg)
import Project
import Return exposing (andThen)
import Store
import Todo
import Todo.Types exposing (TodoAction(TA_AutoSnooze), TodoDoc, TodoStore)
import Toolkit.Operators exposing (..)
import ReturnTypes exposing (..)
import Types exposing (..)
import ViewType exposing (ViewType(EntityListView))
import X.Function exposing (..)
import X.Function.Infix exposing (..)
import List.Extra as List
import Maybe.Extra as Maybe
import X.Record exposing (maybeOverT2, maybeSetIn, overT2, set, setIn)
import Json.Encode as E
import Set
import Tuple2
import X.List
import X.Predicate


filterTodosAndSortBy pred sortBy model =
    Store.filterDocs pred model.todoStore
        |> List.sortBy sortBy


filterTodosAndSortByLatestCreated pred =
    filterTodosAndSortBy pred (Todo.getCreatedAt >> negate)


filterTodosAndSortByLatestModified pred =
    filterTodosAndSortBy pred (Todo.getModifiedAt >> negate)


getActiveTodoListForContext context model =
    filterTodosAndSortByLatestCreated
        (X.Predicate.all
            [ Todo.isActive
            , Todo.contextFilter context
            , Model.Stores.isTodoProjectActive model
            ]
        )
        model


getActiveTodoListForProject project model =
    filterTodosAndSortByLatestCreated
        (X.Predicate.all
            [ Todo.isActive
            , Todo.hasProject project
            , Model.Stores.isTodoContextActive model
            ]
        )
        model


createEntityTreeForViewType : EntityListViewType -> AppModel -> Entity.Tree.Tree
createEntityTreeForViewType viewType model =
    let
        getActiveTodoListForContextHelp =
            getActiveTodoListForContext # model

        getActiveTodoListForProjectHelp =
            getActiveTodoListForProject # model

        findProjectByIdHelp =
            findProjectById # model

        findContextByIdHelp =
            findContextById # model
    in
        case viewType of
            Entity.Types.ContextsView ->
                getActiveContexts model
                    |> Entity.Tree.initContextForest
                        getActiveTodoListForContextHelp

            Entity.Types.ProjectsView ->
                getActiveProjects model
                    |> Entity.Tree.initProjectForest
                        getActiveTodoListForProjectHelp

            Entity.Types.ContextView id ->
                findContextById id model
                    ?= Context.null
                    |> Entity.Tree.initContextRoot
                        getActiveTodoListForContextHelp
                        findProjectByIdHelp

            Entity.Types.ProjectView id ->
                findProjectById id model
                    ?= Project.null
                    |> Entity.Tree.initProjectRoot
                        getActiveTodoListForProjectHelp
                        findContextByIdHelp

            Entity.Types.BinView ->
                Entity.Tree.initTodoForest
                    "Bin"
                    (filterTodosAndSortByLatestModified Document.isDeleted model)

            Entity.Types.DoneView ->
                Entity.Tree.initTodoForest
                    "Done"
                    (filterTodosAndSortByLatestModified
                        (X.Predicate.all [ Document.isNotDeleted, Todo.isDone ])
                        model
                    )

            Entity.Types.RecentView ->
                Entity.Tree.initTodoForest
                    "Recent"
                    (filterTodosAndSortByLatestModified X.Predicate.always model)
