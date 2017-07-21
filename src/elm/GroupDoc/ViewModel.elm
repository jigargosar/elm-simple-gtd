module GroupDoc.ViewModel exposing (..)

import AppColors
import Color
import Context
import Document
import Document.Types exposing (DocId)
import Entity.Types exposing (Entity, EntityId(..), EntityListViewType)
import GroupDoc.Types exposing (..)
import Material
import String.Extra
import Todo.Types exposing (TodoDoc)
import X.Keyboard exposing (KeyboardEvent)
import GroupDoc
import Todo
import Project
import Keyboard.Extra as Key exposing (Key)
import Msg exposing (..)
import Toolkit.Helpers exposing (apply2)
import X.Function exposing (when)


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
    , onCancelClicked : AppMsg
    , icon : IconVM
    , onFocusIn : AppMsg
    , onKeyDownMsg : KeyboardEvent -> AppMsg
    , tabindexAV : Int
    , todoList : List TodoDoc
    , getTabIndexAVForEntityId : EntityId -> Int
    , onMdl : Material.Msg AppMsg -> Msg.AppMsg
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
    , groupDocType : GroupDoc.Types.GroupDocType
    }



--create : Config -> List TodoDoc -> GroupDoc -> GroupDocViewModel


create config configInner todoList groupDoc =
    let
        id =
            Document.getId groupDoc

        entityId =
            configInner.toEntityId id

        groupDocId =
            createGroupDocIdFromType configInner.groupDocType id

        onEntityAction =
            Msg.onEntityUpdateMsg entityId

        isNull =
            configInner.isNull groupDoc

        ( toggleDeleteMsg, toggleArchiveMsg ) =
            if isNull then
                ( Msg.noop, Msg.noop )
            else
                groupDocId
                    |> apply2
                        ( config.onToggleGroupDocArchived
                        , config.onToggleGroupDocArchived
                        )

        startEditingMsg =
            if isNull then
                Msg.noop
            else
                onEntityAction Entity.Types.EUA_StartEditing

        icon =
            if isNull then
                configInner.nullIcon
            else
                { name = configInner.defaultIconName, color = configInner.defaultColor }

        name =
            when String.Extra.isBlank (\_ -> "<no name>") groupDoc.name

        appHeader =
            { name = configInner.namePrefix ++ name, backgroundColor = icon.color }

        onKeyDownMsg { key } =
            case key of
                Key.CharE ->
                    startEditingMsg

                Key.Delete ->
                    toggleDeleteMsg

                Key.CharG ->
                    onEntityAction Entity.Types.EUA_OnGotoEntity

                _ ->
                    Msg.noop

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
                , onClick = toggleArchiveMsg
                , isArchived = isArchived
                }
    in
        { id = id
        , name = name
        , namePrefix = configInner.namePrefix
        , count = todoList |> List.length
        , isEditable = not isNull
        , isDeleted = Document.isDeleted groupDoc
        , archive = archive
        , startEditingMsg = startEditingMsg
        , onDeleteClicked = toggleDeleteMsg
        , onSaveClicked = Msg.onSaveExclusiveModeForm
        , onCancelClicked = Msg.revertExclusiveMode
        , icon = icon
        , onFocusIn = onEntityAction Entity.Types.EUA_OnFocusIn
        , onKeyDownMsg = onKeyDownMsg
        , tabindexAV = configInner.getTabIndexAVForEntityId entityId
        , todoList = todoList
        , getTabIndexAVForEntityId = configInner.getTabIndexAVForEntityId
        , onMdl = Msg.onMdl
        }



--createContextGroupVM : (EntityId -> Int) -> List TodoDoc -> ContextDoc -> GroupDocViewModel


createContextGroupVM config getTabIndexAVForEntityId todoList context =
    let
        configInner : Config
        configInner =
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
            , groupDocType = GroupDoc.Types.ContextGroupDocType
            }
    in
        create config configInner todoList context



--createProjectGroupVM : (EntityId -> Int) -> List TodoDoc -> ProjectDoc -> GroupDocViewModel


createProjectGroupVM config getTabIndexAVForEntityId todoList project =
    let
        configInner : Config
        configInner =
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
            , groupDocType = GroupDoc.Types.ProjectGroupDocType
            }
    in
        create config configInner todoList project


inboxColor =
    AppColors.nullContextColor
