module AppDrawer.GroupViewModel exposing (..)

import AppColors
import AppDrawer.Model
import AppDrawer.Types
import Color
import Context
import Dict
import Dict.Extra
import Document
import Document.Types exposing (DocId)
import Entity.Types exposing (Entity, EntityId(..), EntityListViewType)
import GroupDoc
import GroupDoc.Types
import Msg
import Model
import Msg exposing (..)
import Stores
import Todo
import Todo.Types exposing (TodoDoc)
import Toolkit.Operators exposing (..)
import Model
import Project
import Types exposing (AppModel)
import ViewType exposing (ViewType(EntityListView))
import X.Maybe


type alias IconVM =
    { name : String
    , color : Color.Color
    }


type alias ViewModel =
    { nullVMAsList : List DocumentWithNameViewModel
    , entityList : List DocumentWithNameViewModel
    , archivedEntityList : List DocumentWithNameViewModel
    , viewType : EntityListViewType
    , title : String
    , className : String
    , showArchived : Bool
    , onAddClicked : AppMsg
    , onToggleExpanded : AppMsg
    , onToggleShowArchived : AppMsg
    , isExpanded : Bool
    , icon : IconVM
    }


type alias DocumentWithNameViewModel =
    { id : String
    , name : String
    , appHeader : { name : String, backgroundColor : Color.Color }
    , isDeleted : Bool
    , isEmpty : Bool
    , count : Int
    , onActiveStateChanged : Bool -> AppMsg
    , icon : IconVM
    }


type alias GroupDoc =
    GroupDoc.Types.GroupDoc


type alias Config =
    { groupByFn : TodoDoc -> DocId
    , todoList : List TodoDoc
    , namePrefix : String
    , filter : AppModel -> List GroupDoc
    , toEntityId : DocId -> EntityId
    , nullEntity : GroupDoc
    , isNull : GroupDoc -> Bool
    , nullIcon : IconVM
    , defaultColor : Color.Color
    , defaultIconName : String
    , getViewType : DocId -> EntityListViewType
    }


createList : Config -> AppModel -> List DocumentWithNameViewModel
createList config model =
    let
        todoListDict =
            config.todoList |> Dict.Extra.groupBy config.groupByFn

        getTodoListWithGroupId id =
            todoListDict |> Dict.get id ?= []

        list : List GroupDoc
        list =
            config.filter model
    in
        list .|> create getTodoListWithGroupId config


create getTodoListByEntityId config entity =
    let
        id =
            Document.getId entity

        createEntityActionMsg =
            Msg.onEntityUpdateMsg (config.toEntityId id)

        count =
            getTodoListByEntityId id |> List.length

        isNull =
            config.isNull entity

        icon =
            if isNull then
                config.nullIcon
            else
                { name = config.defaultIconName, color = config.defaultColor }

        name =
            entity.name

        appHeader =
            { name = config.namePrefix ++ name, backgroundColor = icon.color }

        startEditingMsg =
            createEntityActionMsg Entity.Types.EUA_StartEditing
    in
        { id = id
        , name = name
        , isDeleted = Document.isDeleted entity
        , isEmpty = count == 0
        , count = count
        , onActiveStateChanged =
            (\bool ->
                if bool then
                    Msg.OnSetViewType (config.getViewType id |> EntityListView)
                else
                    Model.noop
            )
        , icon = icon
        , appHeader = appHeader
        }


contexts : AppModel -> ViewModel
contexts model =
    let
        archivedFilter =
            Stores.filterContexts GroupDoc.archivedButNotDeletedPred

        activeFilter =
            Stores.filterContexts GroupDoc.isActive

        config : Config
        config =
            { groupByFn = Todo.getContextId
            , todoList = Stores.getActiveTodoListHavingActiveProject model
            , namePrefix = "@"
            , filter = activeFilter
            , toEntityId = ContextId
            , nullEntity = Context.null
            , isNull = Context.isNull
            , nullIcon = { name = "inbox", color = AppColors.nullContextColor }
            , defaultIconName = "fiber_manual_record"
            , defaultColor = AppColors.defaultContextColor
            , getViewType = Entity.Types.ContextView
            }

        archivedConfig =
            { config | filter = archivedFilter }

        entityList =
            createList config model

        nullVMAsList =
            entityList |> List.head |> X.Maybe.toList
    in
        { entityList = entityList |> List.drop 1
        , nullVMAsList = nullVMAsList
        , archivedEntityList = createList archivedConfig model
        , viewType = Entity.Types.ContextsView
        , title = "Contexts"
        , className = "contexts"
        , showArchived = AppDrawer.Model.getArchivedContextsExpanded model.appDrawerModel
        , onAddClicked = Msg.onNewContext
        , icon = { name = "group_work", color = AppColors.contextsColor }
        , onToggleExpanded = Msg.OnAppDrawerMsg AppDrawer.Types.OnToggleContextsExpanded
        , onToggleShowArchived = Msg.OnAppDrawerMsg AppDrawer.Types.OnToggleArchivedContexts
        , isExpanded = AppDrawer.Model.getContextExpanded model.appDrawerModel
        }


projects : AppModel -> ViewModel
projects model =
    let
        archivedFilter =
            Stores.filterProjects GroupDoc.archivedButNotDeletedPred

        activeFilter =
            Stores.filterProjects GroupDoc.isActive

        config : Config
        config =
            { groupByFn = Todo.getProjectId
            , todoList = Stores.getActiveTodoListHavingActiveContext model
            , namePrefix = "#"
            , filter = activeFilter
            , toEntityId = ProjectId
            , nullEntity = Project.null
            , isNull = Project.isNull
            , nullIcon = { name = "apps", color = AppColors.nullProjectColor }
            , defaultIconName = "apps"
            , defaultColor = AppColors.defaultProjectColor
            , getViewType = Entity.Types.ProjectView
            }

        archivedConfig =
            { config | filter = archivedFilter }

        entityList =
            createList config model

        nullVMAsList =
            entityList |> List.head |> X.Maybe.toList
    in
        { entityList = entityList |> List.drop 1
        , nullVMAsList = []
        , archivedEntityList = createList archivedConfig model
        , viewType = Entity.Types.ProjectsView
        , title = "Projects"
        , className = "projects"
        , showArchived = AppDrawer.Model.getArchivedProjectsExpanded model.appDrawerModel
        , onAddClicked = Msg.onNewProject
        , icon = { name = "group_work", color = AppColors.projectsColor }
        , onToggleExpanded = Msg.OnAppDrawerMsg AppDrawer.Types.OnToggleProjectsExpanded
        , onToggleShowArchived = Msg.OnAppDrawerMsg AppDrawer.Types.OnToggleArchivedProjects
        , isExpanded = AppDrawer.Model.getProjectsExpanded model.appDrawerModel
        }
