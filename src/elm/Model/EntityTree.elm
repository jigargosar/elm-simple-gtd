module Model.EntityTree exposing (..)

import Context
import Document
import Entity.Tree
import Model.GroupDocStore exposing (..)
import Model.Stores
import Pages.EntityList exposing (..)
import Project
import Store
import Todo
import Toolkit.Operators exposing (..)
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



--createEntityTreeForPage : EntityListPage -> AppModel -> Entity.Tree.Tree


createEntityTreeFromEntityListPageModel entityListPage model =
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
    case entityListPage of
        ContextsView ->
            getActiveContexts model
                |> Entity.Tree.initContextForest
                    getActiveTodoListForContextHelp

        ProjectsView ->
            getActiveProjects model
                |> Entity.Tree.initProjectForest
                    getActiveTodoListForProjectHelp

        ContextView id ->
            findContextById id model
                ?= Context.null
                |> Entity.Tree.initContextRoot
                    getActiveTodoListForContextHelp
                    findProjectByIdHelp

        ProjectView id ->
            findProjectById id model
                ?= Project.null
                |> Entity.Tree.initProjectRoot
                    getActiveTodoListForProjectHelp
                    findContextByIdHelp

        BinView ->
            Entity.Tree.initTodoForest
                "Bin"
                (filterTodosAndSortByLatestModified Document.isDeleted model)

        DoneView ->
            Entity.Tree.initTodoForest
                "Done"
                (filterTodosAndSortByLatestModified
                    (X.Predicate.all [ Document.isNotDeleted, Todo.isDone ])
                    model
                )

        RecentView ->
            Entity.Tree.initTodoForest
                "Recent"
                (filterTodosAndSortByLatestModified X.Predicate.always model)
