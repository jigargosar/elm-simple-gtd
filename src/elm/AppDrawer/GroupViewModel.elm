module AppDrawer.GroupViewModel exposing (..)

import AppDrawer.Model
import AppDrawer.Types
import Color
import Colors
import Data.TodoDoc
import Dict
import Dict.Extra
import Document
import Entity exposing (..)
import GroupDoc exposing (..)
import Models.GroupDocStore
import Models.Stores
import String.Extra
import Toolkit.Operators exposing (..)
import X.Function exposing (when)
import X.Maybe


type alias IconVM =
    { name : String
    , color : Color.Color
    }


type alias ViewModel msg =
    { nullVMAsList : List (DocumentWithNameViewModel msg)
    , entityList : List (DocumentWithNameViewModel msg)
    , archivedEntityList : List (DocumentWithNameViewModel msg)
    , title : String
    , className : String
    , showArchived : Bool
    , onAddClicked : msg
    , onToggleExpanded : msg
    , onToggleShowArchived : msg
    , isExpanded : Bool
    , icon : IconVM
    }


type alias DocumentWithNameViewModel msg =
    { id : String
    , name : String
    , appHeader : { name : String, backgroundColor : Color.Color }
    , isDeleted : Bool
    , isEmpty : Bool
    , count : Int
    , onActiveStateChanged : Bool -> msg
    , icon : IconVM
    }



--type alias Config =
--    { groupByFn : TodoDoc -> DocId
--    , todoList : List TodoDoc
--    , namePrefix : String
--    , filter : AppModel -> List GroupDoc
--    , toEntityId : DocId -> EntityId
--    , nullEntity : GroupDoc
--    , isNull : GroupDoc -> Bool
--    , nullIcon : IconVM
--    , defaultColor : Color.Color
--    , defaultIconName : String
--    , getEntityListPageModel : DocId -> EntityListPageModel
--    , groupDocType : GroupDocType
--    }
--createList : Config -> AppModel -> List DocumentWithNameViewModel


createList config innerConfig model =
    let
        todoListDict =
            innerConfig.todoList |> Dict.Extra.groupBy innerConfig.groupByFn

        getTodoListWithGroupId id =
            todoListDict |> Dict.get id ?= []

        list : List GroupDoc
        list =
            innerConfig.filter model
    in
    list .|> create getTodoListWithGroupId config innerConfig


create getTodoListByEntityId config innerConFig groupDoc =
    let
        id =
            Document.getId groupDoc

        count =
            getTodoListByEntityId id |> List.length

        isNull =
            innerConFig.isNull groupDoc

        ( icon, path ) =
            if isNull then
                ( innerConFig.nullIcon, [ innerConFig.getEntityListPageModel ] )
            else
                ( { name = innerConFig.defaultIconName, color = innerConFig.defaultColor }
                , [ innerConFig.getEntityListPageModel, id ]
                )

        name =
            when String.Extra.isBlank (\_ -> "<no name>") groupDoc.name

        appHeader =
            { name = innerConFig.namePrefix ++ name, backgroundColor = icon.color }

        groupDocId =
            GroupDoc.createGroupDocIdFromType innerConFig.groupDocType id

        startEditingMsg =
            config.onStartEditingGroupDoc groupDocId
    in
    { id = id
    , name = name
    , isDeleted = Document.isDeleted groupDoc
    , isEmpty = count == 0
    , count = count
    , onActiveStateChanged =
        \bool ->
            if bool then
                config.navigateToPathMsg path
            else
                config.noop
    , icon = icon
    , appHeader = appHeader
    }



--contexts : AppModel -> ViewModel


contexts config model =
    let
        archivedFilter =
            Models.GroupDocStore.filterContexts GroupDoc.archivedButNotDeletedPred

        activeFilter =
            Models.GroupDocStore.filterContexts GroupDoc.isActive

        --        innerConfig : Config
        innerConfig =
            { groupByFn = Data.TodoDoc.getContextId
            , todoList = Models.Stores.getActiveTodoListHavingActiveProject model
            , namePrefix = "@"
            , filter = activeFilter
            , toEntityId = ContextEntityId
            , nullEntity = GroupDoc.nullContext
            , isNull = GroupDoc.isNullContext
            , nullIcon = { name = "inbox", color = Colors.nullContext }
            , defaultIconName = "fiber_manual_record"
            , defaultColor = Colors.defaultContext
            , getEntityListPageModel = "context"
            , groupDocType = ContextGroupDocType
            }

        archivedConfig =
            { innerConfig | filter = archivedFilter }

        entityList =
            createList config innerConfig model

        nullVMAsList =
            entityList |> List.head |> X.Maybe.toList
    in
    { entityList = entityList |> List.drop 1
    , nullVMAsList = nullVMAsList
    , archivedEntityList = createList config archivedConfig model
    , page = [ "contexts" ]
    , title = "Contexts"
    , className = "contexts"
    , showArchived = AppDrawer.Model.getArchivedContextsExpanded model.appDrawerModel
    , onAddClicked = config.onStartAddingGroupDoc ContextGroupDocType
    , icon = { name = "group_work", color = Colors.contexts }
    , onToggleExpanded = config.onAppDrawerMsg AppDrawer.Types.OnToggleContextsExpanded
    , onToggleShowArchived = config.onAppDrawerMsg AppDrawer.Types.OnToggleArchivedContexts
    , isExpanded = AppDrawer.Model.getContextExpanded model.appDrawerModel
    }



--projects : AppModel -> ViewModel


projects config model =
    let
        archivedFilter =
            Models.GroupDocStore.filterProjects GroupDoc.archivedButNotDeletedPred

        activeFilter =
            Models.GroupDocStore.filterProjects GroupDoc.isActive

        --        innerConfig : Config
        innerConfig =
            { groupByFn = Data.TodoDoc.getProjectId
            , todoList = Models.Stores.getActiveTodoListHavingActiveContext model
            , namePrefix = "#"
            , filter = activeFilter
            , toEntityId = ProjectEntityId
            , nullEntity = GroupDoc.nullProject
            , isNull = GroupDoc.isNullProject
            , nullIcon = { name = "apps", color = Colors.nullProject }
            , defaultIconName = "apps"
            , defaultColor = Colors.defaultProject
            , getEntityListPageModel = "project"
            , groupDocType = ProjectGroupDocType
            }

        archivedConfig =
            { innerConfig | filter = archivedFilter }

        entityList =
            createList config innerConfig model

        nullVMAsList =
            entityList |> List.head |> X.Maybe.toList
    in
    { entityList = entityList |> List.drop 1
    , nullVMAsList = []
    , archivedEntityList = createList config archivedConfig model
    , page = [ "projects" ]
    , title = "Projects"
    , className = "projects"
    , showArchived = AppDrawer.Model.getArchivedProjectsExpanded model.appDrawerModel
    , onAddClicked = config.onStartAddingGroupDoc ProjectGroupDocType
    , icon = { name = "group_work", color = Colors.projects }
    , onToggleExpanded = config.onAppDrawerMsg AppDrawer.Types.OnToggleProjectsExpanded
    , onToggleShowArchived = config.onAppDrawerMsg AppDrawer.Types.OnToggleArchivedProjects
    , isExpanded = AppDrawer.Model.getProjectsExpanded model.appDrawerModel
    }
