module GroupDoc.ViewModel exposing (..)

import AppColors
import Color
import Context
import Document
import Document.Types exposing (DocId)
import Entity exposing (Entity)
import Entity.Types exposing (EntityType)
import GroupDoc.Types
import Todo.Types exposing (TodoDoc)
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
    , todoList : List TodoDoc
    , getTabIndexAVForEntity : EntityType -> Int
    }


type alias GroupDoc =
    GroupDoc.Types.GroupDoc


type alias Config =
    { groupByFn : TodoDoc -> DocId
    , namePrefix : String
    , toEntity : GroupDoc -> Entity
    , nullEntity : GroupDoc
    , isNull : GroupDoc -> Bool
    , nullIcon : IconVM
    , defaultColor : Color.Color
    , defaultIconName : String
    , getViewType : DocId -> Entity.Types.ListViewType
    , getTabIndexAVForEntity : EntityType -> Int
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
                onEntityAction Entity.Types.OnToggleDeleted

        startEditingMsg =
            if isNull then
                Model.noop
            else
                onEntityAction Entity.Types.OnStartEditing

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
                    onEntityAction Entity.Types.OnGoto

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
                , onClick = onEntityAction Entity.Types.OnToggleArchived
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
        , onSaveClicked = onEntityAction Entity.Types.OnSave
        , onNameChanged = Entity.Types.OnNameChanged >> onEntityAction
        , onCancelClicked = Msg.OnDeactivateEditingMode
        , icon = icon
        , onFocusIn = onEntityAction Entity.Types.OnOnFocusIn
        , onKeyDownMsg = onKeyDownMsg
        , tabindexAV = config.getTabIndexAVForEntity (config.toEntity groupDoc)
        , todoList = todoList
        , getTabIndexAVForEntity = config.getTabIndexAVForEntity
        }


contextGroup : (EntityType -> Int) -> List TodoDoc -> Context.Model -> ViewModel
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
            , getViewType = Entity.Types.ContextView
            , getTabIndexAVForEntity = getTabIndexAVForEntity
            }
    in
        create config todoList context


projectGroup : (EntityType -> Int) -> List TodoDoc -> Project.Model -> ViewModel
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
            , getViewType = Entity.Types.ProjectView
            , getTabIndexAVForEntity = getTabIndexAVForEntity
            }
    in
        create config todoList project


inboxColor =
    AppColors.nullContextColor
