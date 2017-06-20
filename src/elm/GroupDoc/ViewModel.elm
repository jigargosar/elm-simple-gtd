module GroupDoc.ViewModel exposing (..)

import Context
import Dict
import Document
import ExclusiveMode exposing (ExclusiveMode)
import Entity exposing (Entity)
import Ext.Keyboard exposing (KeyboardEvent)
import GroupDoc
import Html
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


type alias IconVM =
    { name : String
    , color : String
    }


type alias ViewModel =
    { id : String
    , count : Int
    , name : String
    , namePrefix : String
    , isDeleted : Bool
    , archive : { iconName : String, onClick : Msg, isArchived : Bool }
    , isEditable : Bool
    , startEditingMsg : Msg
    , onDeleteClicked : Msg
    , onSaveClicked : Msg
    , onNameChanged : String -> Msg
    , onCancelClicked : Msg
    , icon : IconVM
    , onFocusIn : Msg
    , onKeyDownMsg : KeyboardEvent -> Msg
    , tabindexAV : Html.Attribute Msg
    , todoList : Entity.TodoList
    , getTabIndexAVForEntity : Entity.Entity -> Html.Attribute Msg
    }


type alias GroupDoc =
    GroupDoc.Model


type alias Config =
    { groupByFn : Todo.Model -> Document.Id
    , namePrefix : String
    , entityWrapper : GroupDoc -> Entity
    , nullEntity : GroupDoc
    , isNull : GroupDoc -> Bool
    , nullIcon : IconVM
    , defaultIconName : String
    , getViewType : Document.Id -> EntityListViewType
    , getTabIndexAVForEntity : Entity.Entity -> Html.Attribute Msg
    }


create config todoList groupDoc =
    let
        id =
            Document.getId groupDoc

        onEntityAction =
            Model.OnEntityAction (config.entityWrapper groupDoc)

        isNull =
            config.isNull groupDoc

        toggleDeleteMsg =
            if isNull then
                Model.NOOP
            else
                onEntityAction Entity.ToggleDeleted

        startEditingMsg =
            if isNull then
                Model.NOOP
            else
                onEntityAction Entity.StartEditing

        icon =
            if isNull then
                config.nullIcon
            else
                { name = config.defaultIconName, color = lightGray }

        name =
            groupDoc.name

        appHeader =
            { name = config.namePrefix ++ name, backgroundColor = icon.color }

        onKeyDownMsg { key } =
            case key of
                Key.CharE ->
                    startEditingMsg

                Key.Delete ->
                    toggleDeleteMsg

                Key.CharG ->
                    onEntityAction Entity.Goto

                _ ->
                    commonMsg.noOp

        archive =
            let
                isArchived =
                    GroupDoc.isArchived groupDoc

                iconName =
                    if isArchived then
                        "unarchive"
                    else
                        "archive"
            in
                { iconName = iconName
                , onClick = onEntityAction Entity.ToggleArchived
                , isArchived = isArchived
                }
    in
        { id = id
        , name = name
        , namePrefix = config.namePrefix
        , count = todoList |> List.length
        , isEditable = not isNull
        , isDeleted = Document.isDeleted groupDoc
        , archive = archive
        , startEditingMsg = startEditingMsg
        , onDeleteClicked = toggleDeleteMsg
        , onSaveClicked = onEntityAction Entity.Save
        , onNameChanged = Entity.NameChanged >> onEntityAction
        , onCancelClicked = Model.OnDeactivateEditingMode
        , icon = icon
        , onFocusIn = onEntityAction Entity.OnFocusIn
        , onKeyDownMsg = onKeyDownMsg
        , tabindexAV = config.getTabIndexAVForEntity (config.entityWrapper groupDoc)
        , todoList = todoList
        , getTabIndexAVForEntity = config.getTabIndexAVForEntity
        }


contextGroup : (Entity.Entity -> Html.Attribute Msg) -> Entity.TodoList -> Context.Model -> ViewModel
contextGroup getTabIndexAVForEntity todoList context =
    let
        config : Config
        config =
            { groupByFn = Todo.getContextId
            , namePrefix = "@"
            , entityWrapper = Entity.Context
            , nullEntity = Context.null
            , isNull = Context.isNull
            , nullIcon = { name = "inbox", color = inboxColor }
            , defaultIconName = "av:fiber-manual-record"
            , getViewType = Entity.ContextView
            , getTabIndexAVForEntity = getTabIndexAVForEntity
            }
    in
        create config todoList context


projectGroup : (Entity.Entity -> Html.Attribute Msg) -> Entity.TodoList -> Project.Model -> ViewModel
projectGroup getTabIndexAVForEntity todoList project =
    let
        config : Config
        config =
            { groupByFn = Todo.getProjectId
            , namePrefix = "#"
            , entityWrapper = Entity.Project
            , nullEntity = Project.null
            , isNull = Project.isNull
            , nullIcon = { name = "inbox", color = inboxColor }
            , defaultIconName = "av:fiber-manual-record"
            , getViewType = Entity.ProjectView
            , getTabIndexAVForEntity = getTabIndexAVForEntity
            }
    in
        create config todoList project


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
