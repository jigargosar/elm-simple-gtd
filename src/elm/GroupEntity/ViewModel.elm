module GroupEntity.ViewModel exposing (..)

import Context
import Dict
import Document
import EditMode exposing (EditMode)
import Ext.Keyboard exposing (KeyboardEvent)
import Lazy
import Model exposing (Entity(ContextEntity, ProjectEntity), EntityAction(NameChanged, Save, StartEditing, ToggleDeleted), GroupEntityType(ContextGroup, ProjectGroup), ViewType(..), EntityListViewType(..))
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


type alias IconVM =
    { name : String
    , color : String
    }


type alias ViewModel =
    { entityList : List EntityViewModel
    , viewType : EntityListViewType
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
    , onFocusIn : Msg
    , onFocus : Msg
    , onBlur : Msg
    , onKeyDownMsg : KeyboardEvent -> Msg
    }


type alias DocumentWithName =
    Document.Document { name : String }


type alias Config =
    { groupByFn : Todo.Model -> Document.Id
    , namePrefix : String
    , entityType : GroupEntityType
    , entityWrapper : DocumentWithName -> Entity
    , nullEntity : DocumentWithName
    , isNull : DocumentWithName -> Bool
    , nullIcon : IconVM
    , defaultIconName : String
    , getViewType : Document.Id -> EntityListViewType
    , maybeEditModel : Maybe EditMode.EntityForm
    }


createList : Config -> Model.Model -> List EntityViewModel
createList config model =
    let
        todoListDict =
            Model.getActiveTodoListGroupedBy config.groupByFn model

        getTodoListWithGroupId id =
            todoListDict |> Dict.get id ?= []

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
                (createEntityActionMsg ToggleDeleted)

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
            createEntityActionMsg StartEditing
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
        , onSaveClicked = createEntityActionMsg Save
        , onNameChanged = NameChanged >> createEntityActionMsg
        , onCancelClicked = Msg.DeactivateEditingMode
        , icon = icon
        , appHeader = appHeader
        , onFocusIn = createEntityActionMsg Model.SetFocusedIn
        , onFocus = createEntityActionMsg Model.SetFocused
        , onBlur = createEntityActionMsg Model.SetBlurred
        , onKeyDownMsg = onKeyDownMsg
        }


contexts : Model.Model -> ViewModel
contexts model =
    let
        config : Config
        config =
            { groupByFn = Todo.getContextId
            , namePrefix = "@"
            , entityType = ContextGroup
            , entityWrapper = ContextEntity
            , nullEntity = Context.null
            , isNull = Context.isNull
            , nullIcon = { name = "inbox", color = inboxColor }
            , defaultIconName = "av:fiber-manual-record"
            , getViewType = ContextView
            , maybeEditModel = Model.getMaybeEditModelForEntityType ContextGroup model
            }

        contextList : List EntityViewModel
        contextList =
            createList config model
    in
        { entityList = contextList
        , viewType = ContextsView
        , title = "Contexts"
        , showDeleted = model.showDeleted
        , onAddClicked = Msg.NewContext
        , icon = { name = "group-work", color = contextsColor }
        }


projects : Model.Model -> ViewModel
projects model =
    let
        projectList : List EntityViewModel
        projectList =
            createList
                { groupByFn = Todo.getProjectId
                , namePrefix = "#"
                , entityType = ProjectGroup
                , entityWrapper = ProjectEntity
                , nullEntity = Project.null
                , isNull = Project.isNull
                , nullIcon = { name = "apps", color = nullProjectColor }
                , defaultIconName = "apps"
                , getViewType = ProjectView
                , maybeEditModel = Model.getMaybeEditModelForEntityType ProjectGroup model
                }
                model
    in
        { entityList = projectList
        , viewType = ProjectsView
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
