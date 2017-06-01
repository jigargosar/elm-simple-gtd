module OldGroupEntity.ViewModel exposing (..)

import Context
import Dict
import Document
import EditMode exposing (EditMode)
import Entity exposing (Entity)
import Ext.Keyboard exposing (KeyboardEvent)
import Lazy
import Model exposing (EntityListViewType, ViewType(..))
import Msg exposing (Msg, commonMsg)
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
    , viewType : EntityListViewType
    , title : String
    , showDeleted : Bool
    , onAddClicked : Msg
    , icon : IconVM
    }


type alias DocumentWithNameViewModel =
    { id : String
    , name : String
    , appHeader : { name : String, backgroundColor : String }
    , isDeleted : Bool
    , todoList : List Todo.Model
    , isEmpty : Bool
    , count : Int
    , onActiveStateChanged : Bool -> Msg
    , startEditingMsg : Msg
    , onDeleteClicked : Msg
    , onSaveClicked : Msg
    , onNameChanged : String -> Msg
    , onCancelClicked : Msg
    , icon : IconVM
    , onFocusIn : Msg
    , onFocus : Msg
    , onBlur : Msg
    , onKeyDownMsg : KeyboardEvent -> Msg
    }


type alias Record =
    { name : String }


type alias DocumentWithName =
    Document.Document Record


type alias DocumentWithNameStore =
    Store.Store Record


type alias Config =
    { groupByFn : Todo.Model -> Document.Id
    , namePrefix : String
    , filter : Model.Model -> List DocumentWithName
    , entityWrapper : DocumentWithName -> Entity
    , nullEntity : DocumentWithName
    , isNull : DocumentWithName -> Bool
    , nullIcon : IconVM
    , defaultIconName : String
    , getViewType : Document.Id -> EntityListViewType
    }


createList : Config -> Model.Model -> List DocumentWithNameViewModel
createList config model =
    let
        todoListDict =
            Model.getActiveTodoListGroupedBy config.groupByFn model

        getTodoListWithGroupId id =
            todoListDict |> Dict.get id ?= []

        list : List DocumentWithName
        list =
            config.filter model
    in
        list
            .|> create getTodoListWithGroupId config


create todoListByEntityId config entity =
    let
        id =
            Document.getId entity

        createEntityActionMsg =
            Msg.OnEntityAction (config.entityWrapper entity)

        todoList =
            todoListByEntityId id

        count =
            List.length todoList

        isNull =
            config.isNull entity

        toggleDeleteMsg =
            if isNull then
                (commonMsg.noOp)
            else
                (createEntityActionMsg Entity.ToggleDeleted)

        icon =
            if isNull then
                config.nullIcon
            else
                { name = config.defaultIconName, color = lightGray }

        name =
            entity.name

        appHeader =
            { name = config.namePrefix ++ name, backgroundColor = icon.color }

        onKeyDownMsg { key } =
            case key of
                {- Key.Space ->
                   createEntityActionMsg Model.ToggleSelected
                -}
                Key.CharE ->
                    startEditingMsg

                Key.Delete ->
                    toggleDeleteMsg

                _ ->
                    commonMsg.noOp

        startEditingMsg =
            createEntityActionMsg Entity.StartEditing
    in
        { id = id
        , name = name
        , isDeleted = Document.isDeleted entity
        , todoList = todoList
        , isEmpty = count == 0
        , count = List.length todoList
        , onActiveStateChanged =
            (\bool ->
                if bool then
                    Msg.SwitchView (config.getViewType id |> EntityListView)
                else
                    commonMsg.noOp
            )
        , startEditingMsg = startEditingMsg
        , onDeleteClicked = toggleDeleteMsg
        , onSaveClicked = createEntityActionMsg Entity.Save
        , onNameChanged = Entity.NameChanged >> createEntityActionMsg
        , onCancelClicked = Msg.DeactivateEditingMode
        , icon = icon
        , appHeader = appHeader
        , onFocusIn = createEntityActionMsg Entity.SetFocusedIn
        , onFocus = createEntityActionMsg Entity.SetFocused
        , onBlur = createEntityActionMsg Entity.SetBlurred
        , onKeyDownMsg = onKeyDownMsg
        }


contexts : Model.Model -> ViewModel
contexts model =
    let
        config : Config
        config =
            { groupByFn = Todo.getContextId
            , namePrefix = "@"
            , filter = Model.filterCurrentContexts
            , entityWrapper = Entity.ContextEntity
            , nullEntity = Context.null
            , isNull = Context.isNull
            , nullIcon = { name = "inbox", color = inboxColor }
            , defaultIconName = "av:fiber-manual-record"
            , getViewType = Entity.ContextView
            }

        contextList : List DocumentWithNameViewModel
        contextList =
            createList config model
    in
        { entityList = contextList
        , viewType = Entity.ContextsView
        , title = "Contexts"
        , showDeleted = model.showDeleted
        , onAddClicked = Msg.NewContext
        , icon = { name = "group-work", color = contextsColor }
        }


projects : Model.Model -> ViewModel
projects model =
    let
        config : Config
        config =
            { groupByFn = Todo.getProjectId
            , namePrefix = "#"
            , filter = Model.filterCurrentProjects
            , entityWrapper = Entity.ProjectEntity
            , nullEntity = Project.null
            , isNull = Project.isNull
            , nullIcon = { name = "apps", color = nullProjectColor }
            , defaultIconName = "apps"
            , getViewType = Entity.ProjectView
            }

        projectList : List DocumentWithNameViewModel
        projectList =
            createList config model
    in
        { entityList = projectList
        , viewType = Entity.ProjectsView
        , title = "Projects"
        , showDeleted = model.showDeleted
        , onAddClicked = Msg.NewProject
        , icon =
            { name = "group-work"
            , color = projectsColor
            }
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