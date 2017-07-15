module GroupDoc.ViewModel exposing (..)

import AppColors
import Color
import Context
import Document
import Document.Types exposing (DocId)
import Entity.Types exposing (Entity, EntityId(..), EntityListViewType)
import GroupDoc.Types
import Todo.Types exposing (TodoDoc)
import X.Keyboard exposing (KeyboardEvent)
import GroupDoc
import Model exposing (commonMsg)
import Todo
import Model
import Project
import Keyboard.Extra as Key exposing (Key)
import Msg exposing (..)
import XMMsg


type alias IconVM =
    { name : String
    , color : Color.Color
    }


type alias GroupDocViewModel =
    { id : String
    , count : Int
    , name : String
    , namePrefix : String
    , isDeleted : Bool
    , archive : { iconName : String, onClick : AppMsg, isArchived : Bool }
    , isEditable : Bool
    , startEditingMsg : AppMsg
    , onDeleteClicked : AppMsg
    , onSaveClicked : AppMsg
    , onNameChanged : String -> AppMsg
    , onCancelClicked : AppMsg
    , icon : IconVM
    , onFocusIn : AppMsg
    , onKeyDownMsg : KeyboardEvent -> AppMsg
    , tabindexAV : Int
    , todoList : List TodoDoc
    , getTabIndexAVForEntityId : EntityId -> Int
    }


type alias GroupDoc =
    GroupDoc.Types.GroupDoc


type alias Config =
    { groupByFn : TodoDoc -> DocId
    , namePrefix : String
    , toEntityId : DocId -> EntityId
    , nullEntity : GroupDoc
    , isNull : GroupDoc -> Bool
    , nullIcon : IconVM
    , defaultColor : Color.Color
    , defaultIconName : String
    , getViewType : DocId -> EntityListViewType
    , getTabIndexAVForEntityId : EntityId -> Int
    }


create : Config -> List TodoDoc -> GroupDoc -> GroupDocViewModel
create config todoList groupDoc =
    let
        id =
            Document.getId groupDoc

        entityId =
            config.toEntityId id

        onEntityAction =
            Msg.onEntityUpdateMsg entityId

        isNull =
            config.isNull groupDoc

        toggleDeleteMsg =
            if isNull then
                Model.noop
            else
                onEntityAction Entity.Types.EUA_ToggleDeleted

        startEditingMsg =
            if isNull then
                Model.noop
            else
                onEntityAction Entity.Types.EUA_StartEditing

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
                    onEntityAction Entity.Types.OnGotoEntity

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
                , onClick = onEntityAction Entity.Types.EUA_ToggleArchived
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
        , onSaveClicked = Msg.OnSaveExclusiveModeForm
        , onNameChanged = Entity.Types.EUA_SetFormText >> onEntityAction
        , onCancelClicked = XMMsg.onSetExclusiveModeToNoneAndTryRevertingFocus
        , icon = icon
        , onFocusIn = onEntityAction Entity.Types.EUA_OnFocusIn
        , onKeyDownMsg = onKeyDownMsg
        , tabindexAV = config.getTabIndexAVForEntityId entityId
        , todoList = todoList
        , getTabIndexAVForEntityId = config.getTabIndexAVForEntityId
        }


contextGroup : (EntityId -> Int) -> List TodoDoc -> Context.Model -> GroupDocViewModel
contextGroup getTabIndexAVForEntityId todoList context =
    let
        config : Config
        config =
            { groupByFn = Todo.getContextId
            , namePrefix = "@"
            , toEntityId = ContextId
            , nullEntity = Context.null
            , isNull = Context.isNull
            , nullIcon = { name = "inbox", color = inboxColor }
            , defaultColor = AppColors.defaultProjectColor
            , defaultIconName = "av:fiber-manual-record"
            , getViewType = Entity.Types.ContextView
            , getTabIndexAVForEntityId = getTabIndexAVForEntityId
            }
    in
        create config todoList context


projectGroup : (EntityId -> Int) -> List TodoDoc -> Project.Model -> GroupDocViewModel
projectGroup getTabIndexAVForEntityId todoList project =
    let
        config : Config
        config =
            { groupByFn = Todo.getProjectId
            , namePrefix = "#"
            , toEntityId = ProjectId
            , nullEntity = Project.null
            , isNull = Project.isNull
            , nullIcon = { name = "inbox", color = inboxColor }
            , defaultColor = AppColors.defaultProjectColor
            , defaultIconName = "av:fiber-manual-record"
            , getViewType = Entity.Types.ProjectView
            , getTabIndexAVForEntityId = getTabIndexAVForEntityId
            }
    in
        create config todoList project


inboxColor =
    AppColors.nullContextColor
