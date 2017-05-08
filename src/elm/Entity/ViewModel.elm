module Entity.ViewModel exposing (..)

import Context
import Dict
import Document
import EditMode exposing (EditForm)
import Lazy
import Model.Types exposing (Entity(ContextEntity, ProjectEntity), EntityAction(ToggleDeleted, NameChanged, Save, StartEditing), EntityStoreType(ContextEntityStoreType, ProjectEntityStoreType), GroupByEntityType(ContextEntityType, ProjectEntityType), MainViewType(ContextView, GroupByContextView, GroupByProjectView, ProjectView))
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


type alias IconVM =
    { name : String
    , color : String
    }


type alias ViewModel =
    { entityList : List EntityViewModel
    , viewType : MainViewType
    , title : String
    , showDeleted : Bool
    , onAddClicked : Msg
    , icon : IconVM
    }


type alias EntityViewModel =
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
    }


type alias DocumentWithName =
    Document.Document { name : String }


type alias Config =
    { groupByFn : Todo.Model -> Document.Id
    , namePrefix : String
    , entityType : GroupByEntityType
    , entityWrapper : DocumentWithName -> Entity
    , nullEntity : DocumentWithName
    , isNull : DocumentWithName -> Bool
    , nullIcon : IconVM
    , defaultIconName : String
    , getViewType : Document.Id -> MainViewType
    , maybeEditModel : Maybe EditMode.EntityForm
    }


createList : Config -> Model.Types.Model -> List EntityViewModel
createList config model =
    let
        todoListDict =
            Model.getActiveTodoListGroupedBy config.groupByFn model

        getTodoListWithGroupId id =
            todoListDict |> Dict.get id ?= []

        appendDeletedEntityList =
            if model.showDeleted then
                List.append # (Model.getDeletedEntityList config.entityType model)
            else
                identity

        --        entityList =
        --            Model.getActiveEntityList config.entityType model
        --                |> (::) config.nullEntity
        --                |> appendDeletedEntityList
        entityList =
            if model.showDeleted then
                Model.getDeletedEntityList config.entityType model
            else
                Model.getActiveEntityList config.entityType model
                    |> (::) config.nullEntity
    in
        entityList
            .|> create getTodoListWithGroupId config


create todoListByEntityId config entity =
    let
        id =
            Document.getId entity

        onEntityAction =
            Msg.OnEntityAction (config.entityWrapper entity)

        todoList =
            todoListByEntityId id

        count =
            List.length todoList

        isNull =
            config.isNull entity

        onDeleteClicked =
            if isNull then
                (commonMsg.noOp)
            else
                (onEntityAction ToggleDeleted)

        maybeEditModel =
            config.maybeEditModel
                ?+> (\editModel ->
                        if editModel.id == id then
                            Just editModel
                        else
                            Nothing
                    )

        icon =
            if isNull then
                config.nullIcon
            else
                { name = config.defaultIconName, color = lightGray }

        name =
            entity.name

        appHeader =
            { name = config.namePrefix ++ name, backgroundColor = icon.color }
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
                    Msg.SetView (config.getViewType id)
                else
                    commonMsg.noOp
            )
        , startEditingMsg = onEntityAction StartEditing
        , onDeleteClicked = onDeleteClicked
        , onSaveClicked = onEntityAction Save
        , onNameChanged = NameChanged >> onEntityAction
        , onCancelClicked = Msg.DeactivateEditingMode
        , icon = icon
        , appHeader = appHeader
        }


contexts : Model.Types.Model -> ViewModel
contexts model =
    let
        config : Config
        config =
            { groupByFn = Todo.getContextId
            , namePrefix = "@"
            , entityType = ContextEntityType
            , entityWrapper = ContextEntity
            , nullEntity = Context.null
            , isNull = Context.isNull
            , nullIcon = { name = "inbox", color = inboxColor }
            , defaultIconName = "av:fiber-manual-record"
            , getViewType = ContextView
            , maybeEditModel = Model.getMaybeEditModelForEntityType ContextEntityType model
            }

        contextList : List EntityViewModel
        contextList =
            createList config model
    in
        { entityList = contextList
        , viewType = GroupByContextView
        , title = "Contexts"
        , showDeleted = model.showDeleted
        , onAddClicked = Msg.NewContext
        , icon = { name = "group-work", color = contextsColor }
        }


projects : Model.Types.Model -> ViewModel
projects model =
    let
        projectList : List EntityViewModel
        projectList =
            createList
                { groupByFn = Todo.getProjectId
                , namePrefix = "#"
                , entityType = ProjectEntityType
                , entityWrapper = ProjectEntity
                , nullEntity = Project.null
                , isNull = Project.isNull
                , nullIcon = { name = "apps", color = nullProjectColor }
                , defaultIconName = "apps"
                , getViewType = ProjectView
                , maybeEditModel = Model.getMaybeEditModelForEntityType ProjectEntityType model
                }
                model
    in
        { entityList = projectList
        , viewType = GroupByProjectView
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
