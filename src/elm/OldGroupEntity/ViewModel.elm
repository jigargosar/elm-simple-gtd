module OldGroupEntity.ViewModel exposing (..)

import AppDrawer.Model
import Context
import Dict
import Dict.Extra
import Document
import ExclusiveMode exposing (ExclusiveMode)
import Entity exposing (Entity)
import Ext.Keyboard exposing (KeyboardEvent)
import GroupDoc
import Lazy
import Model exposing (EntityListViewType, ViewType(..))
import Model exposing (Msg, commonMsg)
import Todo
import Toolkit.Helpers exposing (..)
import Toolkit.Operators exposing (..)
import Ext.Function exposing (..)
import Ext.Function.Infix exposing (..)
import List.Extra as List
import Maybe.Extra as Maybe
import Model
import Project
import Keyboard.Extra as Key exposing (Key)
import Store


type alias IconVM =
    { name : String
    , color : String
    }


type alias ViewModel =
    { entityList : List DocumentWithNameViewModel
    , archivedEntityList : List DocumentWithNameViewModel
    , viewType : EntityListViewType
    , title : String
    , className : String
    , showDeleted : Bool
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
    , appHeader : { name : String, backgroundColor : String }
    , isDeleted : Bool
    , isEmpty : Bool
    , count : Int
    , onActiveStateChanged : Bool -> Msg
    , icon : IconVM
    }


type alias Record =
    { name : String, archived : Bool }


type alias GroupDoc =
    GroupDoc.Model


type alias Config =
    { groupByFn : Todo.Model -> Document.Id
    , todoList : List Todo.Model
    , namePrefix : String
    , filter : Model.Model -> List GroupDoc
    , entityWrapper : GroupDoc -> Entity
    , nullEntity : GroupDoc
    , isNull : GroupDoc -> Bool
    , nullIcon : IconVM
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
            Model.OnEntityAction (config.entityWrapper entity)

        count =
            getTodoListByEntityId id |> List.length

        isNull =
            config.isNull entity

        icon =
            if isNull then
                config.nullIcon
            else
                { name = config.defaultIconName, color = lightGray }

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
                    Model.SwitchView (config.getViewType id |> EntityListView)
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
            , todoList = Model.getActiveTodoListHavingActiveProjects model
            , namePrefix = "@"
            , filter = activeFilter
            , entityWrapper = Entity.ContextEntity
            , nullEntity = Context.null
            , isNull = Context.isNull
            , nullIcon = { name = "inbox", color = inboxColor }
            , defaultIconName = "fiber_manual_record"
            , getViewType = Entity.ContextView
            }

        archivedConfig =
            { config | filter = archivedFilter }
    in
        { entityList = createList config model
        , archivedEntityList = createList archivedConfig model
        , viewType = Entity.ContextsView
        , title = "Contexts"
        , className = "contexts"
        , showDeleted = model.showDeleted
        , showArchived = AppDrawer.Model.getShowArchivedForContexts model.appDrawerModel
        , onAddClicked = Model.NewContext
        , icon = { name = "group_work", color = contextsColor }
        , onToggleExpanded = Model.OnAppDrawerMsg AppDrawer.Model.OnToggleExpandContextList
        , onToggleShowArchived = Model.OnAppDrawerMsg AppDrawer.Model.OnToggleShowArchivedContexts
        , isExpanded = AppDrawer.Model.isContextListExpanded model.appDrawerModel
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
            , todoList = Model.getActiveTodoListHavingActiveContexts model
            , namePrefix = "#"
            , filter = activeFilter
            , entityWrapper = Entity.ProjectEntity
            , nullEntity = Project.null
            , isNull = Project.isNull
            , nullIcon = { name = "apps", color = nullProjectColor }
            , defaultIconName = "apps"
            , getViewType = Entity.ProjectView
            }

        archivedConfig =
            { config | filter = archivedFilter }
    in
        { entityList = createList config model
        , archivedEntityList = createList archivedConfig model
        , viewType = Entity.ProjectsView
        , title = "Projects"
        , className = "projects"
        , showDeleted = model.showDeleted
        , showArchived = AppDrawer.Model.getShowArchivedForProjects model.appDrawerModel
        , onAddClicked = Model.NewProject
        , icon = { name = "group_work", color = projectsColor }
        , onToggleExpanded = Model.OnAppDrawerMsg AppDrawer.Model.OnToggleExpandProjectList
        , onToggleShowArchived = Model.OnAppDrawerMsg AppDrawer.Model.OnToggleShowArchivedProjects
        , isExpanded = AppDrawer.Model.isProjectListExpanded model.appDrawerModel
        }


inboxColor =
    "#42a5f5"


contextsColor =
    sgtdBlue


nullProjectColor =
    --paper-deep-purple-200
    "rgb(179, 157, 219)"


projectsColor =
    --paper-deep-purple-a200
    "rgb(124, 77, 255)"


sgtdBlue =
    --paper-blue-a200
    "rgb(68, 138, 255)"


lightGray =
    --paper-grey-500
    "#9e9e9e"
