module GroupDoc.ViewModel exposing (..)

import AppColors
import Color
import Document
import Entity exposing (..)
import GroupDoc
import Keyboard.Extra as Key exposing (Key)
import Material
import Pages.EntityListOld exposing (..)
import String.Extra
import Todo
import Toolkit.Helpers exposing (apply2)
import Types.Document exposing (..)
import Types.GroupDoc exposing (..)
import Types.Todo exposing (..)
import X.Function exposing (when)
import X.Keyboard exposing (KeyboardEvent)


type alias IconVM =
    { name : String
    , color : Color.Color
    }


type alias GroupDocViewModel msg =
    { id : String
    , key : String
    , count : Int
    , name : String
    , namePrefix : String
    , isDeleted : Bool
    , archive : { iconName : String, onClick : msg, isArchived : Bool }
    , isEditable : Bool
    , startEditingMsg : msg
    , onDeleteClicked : msg
    , onSaveClicked : msg
    , onCancelClicked : msg
    , icon : IconVM
    , onFocusIn : msg
    , onKeyDownMsg : KeyboardEvent -> msg
    , tabindexAV : Int
    , todoList : List TodoDoc
    , getTabIndexAVForEntityId : EntityId -> Int
    , onMdl : Material.Msg msg -> msg
    }


type alias GroupDoc =
    Types.GroupDoc.GroupDoc


type alias Config =
    { groupByFn : TodoDoc -> DocId
    , namePrefix : String
    , toEntityId : DocId -> EntityId
    , nullEntity : GroupDoc
    , isNull : GroupDoc -> Bool
    , nullIcon : IconVM
    , defaultColor : Color.Color
    , defaultIconName : String
    , getPage : DocId -> Old_EntityListPageModel
    , getTabIndexAVForEntityId : EntityId -> Int
    , groupDocType : Types.GroupDoc.GroupDocType
    }



--create : Config -> List TodoDoc -> GroupDoc -> GroupDocViewModel


create config configInner todoList groupDoc =
    let
        id =
            Document.getId groupDoc

        entityId =
            configInner.toEntityId id

        groupDocId =
            GroupDoc.createGroupDocIdFromType configInner.groupDocType id

        isNull =
            configInner.isNull groupDoc

        ( toggleDeleteMsg, toggleArchiveMsg ) =
            if isNull then
                ( config.noop, config.noop )
            else
                groupDocId
                    |> apply2
                        ( config.onToggleGroupDocArchived
                        , config.onToggleGroupDocArchived
                        )

        startEditingMsg =
            if isNull then
                config.noop
            else
                config.onStartEditingGroupDoc groupDocId

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

                _ ->
                    config.noop

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
    , key = toString groupDocId
    , name = name
    , namePrefix = configInner.namePrefix
    , count = todoList |> List.length
    , isEditable = not isNull
    , isDeleted = Document.isDeleted groupDoc
    , archive = archive
    , startEditingMsg = startEditingMsg
    , onDeleteClicked = toggleDeleteMsg
    , onSaveClicked = config.onSaveExclusiveModeForm
    , onCancelClicked = config.revertExclusiveMode
    , icon = icon
    , onFocusIn = config.setFocusInEntityWithEntityId entityId
    , onKeyDownMsg = onKeyDownMsg
    , tabindexAV = configInner.getTabIndexAVForEntityId entityId
    , todoList = todoList
    , getTabIndexAVForEntityId = configInner.getTabIndexAVForEntityId
    , onMdl = config.onMdl
    }



--createContextGroupVM : (EntityId -> Int) -> List TodoDoc -> ContextDoc -> GroupDocViewModel


createContextGroupVM config getTabIndexAVForEntityId todoList context =
    let
        configInner : Config
        configInner =
            { groupByFn = Todo.getContextId
            , namePrefix = "@"
            , toEntityId = ContextId
            , nullEntity = GroupDoc.nullContext
            , isNull = GroupDoc.isNullContext
            , nullIcon = { name = "inbox", color = inboxColor }
            , defaultColor = AppColors.defaultProjectColor
            , defaultIconName = "av:fiber-manual-record"
            , getPage = ContextView
            , getTabIndexAVForEntityId = getTabIndexAVForEntityId
            , groupDocType = Types.GroupDoc.ContextGroupDocType
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
            , nullEntity = GroupDoc.nullProject
            , isNull = GroupDoc.isNullProject
            , nullIcon = { name = "inbox", color = inboxColor }
            , defaultColor = AppColors.defaultProjectColor
            , defaultIconName = "av:fiber-manual-record"
            , getPage = ProjectView
            , getTabIndexAVForEntityId = getTabIndexAVForEntityId
            , groupDocType = Types.GroupDoc.ProjectGroupDocType
            }
    in
    create config configInner todoList project


inboxColor =
    AppColors.nullContextColor
