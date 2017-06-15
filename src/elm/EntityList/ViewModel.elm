module EntityList.ViewModel exposing (..)

import Context
import Dict
import Document
import ExclusiveMode exposing (ExclusiveMode)
import Entity exposing (Entity)
import Ext.Keyboard exposing (KeyboardEvent)
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


type alias GroupViewModel =
    { id : String
    , count : Int
    , name : String
    , isDeleted : Bool
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


type alias DocumentWithName =
    Document.Document { name : String }


type alias Config =
    { groupByFn : Todo.Model -> Document.Id
    , namePrefix : String
    , entityWrapper : DocumentWithName -> Entity
    , nullEntity : DocumentWithName
    , isNull : DocumentWithName -> Bool
    , nullIcon : IconVM
    , defaultIconName : String
    , getViewType : Document.Id -> EntityListViewType
    , getTabIndexAVForEntity : Entity.Entity -> Html.Attribute Msg
    }


create config todoList entityModel =
    let
        id =
            Document.getId entityModel

        createEntityActionMsg =
            Model.OnEntityAction (config.entityWrapper entityModel)

        isNull =
            config.isNull entityModel

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
            entityModel.name

        appHeader =
            { name = config.namePrefix ++ name, backgroundColor = icon.color }

        onKeyDownMsg { key } =
            case key of
                Key.CharE ->
                    startEditingMsg

                Key.Delete ->
                    toggleDeleteMsg

                Key.CharG ->
                    createEntityActionMsg Entity.Goto

                _ ->
                    commonMsg.noOp

        startEditingMsg =
            createEntityActionMsg Entity.StartEditing
    in
        { id = id
        , name = name
        , count = todoList |> List.length
        , isEditable = not isNull
        , isDeleted = Document.isDeleted entityModel
        , startEditingMsg = startEditingMsg
        , onDeleteClicked = toggleDeleteMsg
        , onSaveClicked = createEntityActionMsg Entity.Save
        , onNameChanged = Entity.NameChanged >> createEntityActionMsg
        , onCancelClicked = Model.OnDeactivateEditingMode
        , icon = icon
        , onFocusIn = createEntityActionMsg Entity.OnFocusIn
        , onKeyDownMsg = onKeyDownMsg
        , tabindexAV = config.getTabIndexAVForEntity (config.entityWrapper entityModel)
        , todoList = todoList
        , getTabIndexAVForEntity = config.getTabIndexAVForEntity
        }


contextGroup : (Entity.Entity -> Html.Attribute Msg) -> Entity.TodoList -> Context.Model -> GroupViewModel
contextGroup getTabIndexAVForEntity todoList context =
    let
        config : Config
        config =
            { groupByFn = Todo.getContextId
            , namePrefix = "@"
            , entityWrapper = Entity.ContextEntity
            , nullEntity = Context.null
            , isNull = Context.isNull
            , nullIcon = { name = "inbox", color = inboxColor }
            , defaultIconName = "av:fiber-manual-record"
            , getViewType = Entity.ContextView
            , getTabIndexAVForEntity = getTabIndexAVForEntity
            }
    in
        create config todoList context


forProject : (Entity.Entity -> Html.Attribute Msg) -> Entity.TodoList -> Project.Model -> GroupViewModel
forProject getTabIndexAVForEntity todoList project =
    let
        config : Config
        config =
            { groupByFn = Todo.getProjectId
            , namePrefix = "@"
            , entityWrapper = Entity.ProjectEntity
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
