module GroupDoc.ViewModel exposing (..)

import AppColors
import Color
import Context
import Document
import Entity exposing (Entity)
import X.Keyboard exposing (KeyboardEvent)
import GroupDoc
import Html
import Model exposing (commonMsg)
import Todo
import Model
import Project
import Keyboard.Extra as Key exposing (Key)
import Msg exposing (..)


type alias IconVM =
    { name : String
    , color : Color.Color
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
    , tabindexAV : Int
    , todoList : List Todo.Model
    , getTabIndexAVForEntity : Entity.Entity -> Int
    }


type alias GroupDoc =
    GroupDoc.Model


type alias Config =
    { groupByFn : Todo.Model -> Document.Id
    , namePrefix : String
    , toEntity : GroupDoc -> Entity
    , nullEntity : GroupDoc
    , isNull : GroupDoc -> Bool
    , nullIcon : IconVM
    , defaultColor : Color.Color
    , defaultIconName : String
    , getViewType : Document.Id -> EntityListViewType
    , getTabIndexAVForEntity : Entity.Entity -> Int
    }


create config todoList groupDoc =
    let
        id =
            Document.getId groupDoc

        onEntityAction =
            Msg.OnEntityMsg (config.toEntity groupDoc)

        isNull =
            config.isNull groupDoc

        toggleDeleteMsg =
            if isNull then
                Model.noop
            else
                onEntityAction Entity.ToggleDeleted

        startEditingMsg =
            if isNull then
                Model.noop
            else
                onEntityAction Entity.StartEditing

        icon =
            if isNull then
                config.nullIcon
            else
                { name = config.defaultIconName, color = config.defaultColor }

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
                    Model.noop

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
        , onCancelClicked = Msg.OnDeactivateEditingMode
        , icon = icon
        , onFocusIn = onEntityAction Entity.OnFocusIn
        , onKeyDownMsg = onKeyDownMsg
        , tabindexAV = config.getTabIndexAVForEntity (config.toEntity groupDoc)
        , todoList = todoList
        , getTabIndexAVForEntity = config.getTabIndexAVForEntity
        }


contextGroup : (Entity.Entity -> Int) -> List Todo.Model -> Context.Model -> ViewModel
contextGroup getTabIndexAVForEntity todoList context =
    let
        config : Config
        config =
            { groupByFn = Todo.getContextId
            , namePrefix = "@"
            , toEntity = Entity.fromContext
            , nullEntity = Context.null
            , isNull = Context.isNull
            , nullIcon = { name = "inbox", color = inboxColor }
            , defaultColor = AppColors.defaultProjectColor
            , defaultIconName = "av:fiber-manual-record"
            , getViewType = Entity.ContextView
            , getTabIndexAVForEntity = getTabIndexAVForEntity
            }
    in
        create config todoList context


projectGroup : (Entity.Entity -> Int) -> List Todo.Model -> Project.Model -> ViewModel
projectGroup getTabIndexAVForEntity todoList project =
    let
        config : Config
        config =
            { groupByFn = Todo.getProjectId
            , namePrefix = "#"
            , toEntity = Entity.fromProject
            , nullEntity = Project.null
            , isNull = Project.isNull
            , nullIcon = { name = "inbox", color = inboxColor }
            , defaultColor = AppColors.defaultProjectColor
            , defaultIconName = "av:fiber-manual-record"
            , getViewType = Entity.ProjectView
            , getTabIndexAVForEntity = getTabIndexAVForEntity
            }
    in
        create config todoList project


inboxColor =
    AppColors.nullContextColor
