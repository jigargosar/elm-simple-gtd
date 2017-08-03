module GroupDoc.ViewModel exposing (..)

import Color
import Colors
import Data.TodoDoc exposing (..)
import Document exposing (..)
import Entity exposing (..)
import GroupDoc exposing (..)
import Keyboard.Extra as Key exposing (Key)
import Material
import String.Extra
import Toolkit.Helpers exposing (apply2)
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
    GroupDoc.GroupDoc


type alias Config =
    { groupByFn : TodoDoc -> DocId
    , namePrefix : String
    , toEntityId : DocId -> EntityId
    , nullEntity : GroupDoc
    , isNull : GroupDoc -> Bool
    , nullIcon : IconVM
    , defaultColor : Color.Color
    , defaultIconName : String
    , getTabIndexAVForEntityId : EntityId -> Int
    , groupDocType : GroupDoc.GroupDocType
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


createContextGroupVM config getTabIndexAVForEntityId todoList context =
    let
        configInner : Config
        configInner =
            { groupByFn = Data.TodoDoc.getContextId
            , namePrefix = "@"
            , toEntityId = ContextEntityId
            , nullEntity = GroupDoc.nullContext
            , isNull = GroupDoc.isNullContext
            , nullIcon = { name = "inbox", color = inboxColor }
            , defaultColor = Colors.defaultProject
            , defaultIconName = "av:fiber-manual-record"
            , getTabIndexAVForEntityId = getTabIndexAVForEntityId
            , groupDocType = GroupDoc.ContextGroupDocType
            }
    in
    create config configInner todoList context


createProjectGroupVM config getTabIndexAVForEntityId todoList project =
    let
        configInner : Config
        configInner =
            { groupByFn = Data.TodoDoc.getProjectId
            , namePrefix = "#"
            , toEntityId = ProjectEntityId
            , nullEntity = GroupDoc.nullProject
            , isNull = GroupDoc.isNullProject
            , nullIcon = { name = "inbox", color = inboxColor }
            , defaultColor = Colors.defaultProject
            , defaultIconName = "av:fiber-manual-record"
            , getTabIndexAVForEntityId = getTabIndexAVForEntityId
            , groupDocType = GroupDoc.ProjectGroupDocType
            }
    in
    create config configInner todoList project


inboxColor =
    Colors.nullContext
