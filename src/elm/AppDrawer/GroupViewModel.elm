module AppDrawer.GroupViewModel exposing (..)

import AppColors
import AppDrawer.Model
import Color
import Context
import Dict
import Dict.Extra
import Document
import Entity exposing (Entity)
import GroupDoc
import Model exposing (EntityListViewType, ViewType(..))
import Model exposing (Msg, commonMsg)
import Todo
import Toolkit.Operators exposing (..)
import Model
import Project
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
    , onAddClicked : Msg
    , onToggleExpanded : Msg
    , onToggleShowArchived : Msg
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
    , onActiveStateChanged : Bool -> Msg
    , icon : IconVM
    }


type alias GroupDoc =
    GroupDoc.Model


type alias Config =
    { groupByFn : Todo.Model -> Document.Id
    , todoList : List Todo.Model
    , namePrefix : String
    , filter : Model.Model -> List GroupDoc
    , toEntity : GroupDoc -> Entity
    , nullEntity : GroupDoc
    , isNull : GroupDoc -> Bool
    , nullIcon : IconVM
    , defaultColor : Color.Color
    , defaultIconName : String
    , getViewType : Document.Id -> EntityListViewType
    }


createList : Config -> Model.Model -> List DocumentWithNameViewModel
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
            Model.OnEntityMsg (config.toEntity entity)

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
            createEntityActionMsg Entity.StartEditing
    in
        { id = id
        , name = name
        , isDeleted = Document.isDeleted entity
        , isEmpty = count == 0
        , count = count
        , onActiveStateChanged =
            (\bool ->
                if bool then
                    Model.OnSetViewType (config.getViewType id |> EntityListView)
                else
                    commonMsg.noOp
            )
        , icon = icon
        , appHeader = appHeader
        }


contexts : Model.Model -> ViewModel
contexts model =
    let
        archivedFilter =
            Model.filterContexts GroupDoc.archivedButNotDeletedPred

        activeFilter =
            Model.filterContexts GroupDoc.isActive

        config : Config
        config =
            { groupByFn = Todo.getContextId
            , todoList = Model.getActiveTodoListHavingActiveProject model
            , namePrefix = "@"
            , filter = activeFilter
            , toEntity = Entity.fromContext
            , nullEntity = Context.null
            , isNull = Context.isNull
            , nullIcon = { name = "inbox", color = AppColors.nullContextColor }
            , defaultIconName = "fiber_manual_record"
            , defaultColor = AppColors.defaultContextColor
            , getViewType = Entity.ContextView
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
        , viewType = Entity.ContextsView
        , title = "Contexts"
        , className = "contexts"
        , showArchived = AppDrawer.Model.getArchivedContextsExpanded model.appDrawerModel
        , onAddClicked = Model.NewContext
        , icon = { name = "group_work", color = AppColors.contextsColor }
        , onToggleExpanded = Model.OnAppDrawerMsg AppDrawer.Model.OnToggleContextsExpanded
        , onToggleShowArchived = Model.OnAppDrawerMsg AppDrawer.Model.OnToggleArchivedContexts
        , isExpanded = AppDrawer.Model.getContextExpanded model.appDrawerModel
        }


projects : Model.Model -> ViewModel
projects model =
    let
        archivedFilter =
            Model.filterProjects GroupDoc.archivedButNotDeletedPred

        activeFilter =
            Model.filterProjects GroupDoc.isActive

        config : Config
        config =
            { groupByFn = Todo.getProjectId
            , todoList = Model.getActiveTodoListHavingActiveContext model
            , namePrefix = "#"
            , filter = activeFilter
            , toEntity = Entity.fromProject
            , nullEntity = Project.null
            , isNull = Project.isNull
            , nullIcon = { name = "apps", color = AppColors.nullProjectColor }
            , defaultIconName = "apps"
            , defaultColor = AppColors.defaultProjectColor
            , getViewType = Entity.ProjectView
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
        , viewType = Entity.ProjectsView
        , title = "Projects"
        , className = "projects"
        , showArchived = AppDrawer.Model.getArchivedProjectsExpanded model.appDrawerModel
        , onAddClicked = Model.NewProject
        , icon = { name = "group_work", color = AppColors.projectsColor }
        , onToggleExpanded = Model.OnAppDrawerMsg AppDrawer.Model.OnToggleProjectsExpanded
        , onToggleShowArchived = Model.OnAppDrawerMsg AppDrawer.Model.OnToggleArchivedProjects
        , isExpanded = AppDrawer.Model.getProjectsExpanded model.appDrawerModel
        }
