module EntityList.GroupViewModel exposing (..)

import Context
import Dict
import Document
import EditMode exposing (EditMode)
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


type alias ViewModel =
    { id : String
    , count : Int
    , name : String
    , isDeleted : Bool
    , startEditingMsg : Msg
    , onDeleteClicked : Msg
    , onSaveClicked : Msg
    , onNameChanged : String -> Msg
    , onCancelClicked : Msg
    , icon : IconVM
    , onFocusIn : Msg
    , onKeyDownMsg : KeyboardEvent -> Msg
    , tabindexAV : Html.Attribute Msg
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
    , tabindexAV : Html.Attribute Msg
    }


create tabindexAV config entityModel =
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
        , count = 0
        , isDeleted = Document.isDeleted entityModel
        , startEditingMsg = startEditingMsg
        , onDeleteClicked = toggleDeleteMsg
        , onSaveClicked = createEntityActionMsg Entity.Save
        , onNameChanged = Entity.NameChanged >> createEntityActionMsg
        , onCancelClicked = Model.DeactivateEditingMode
        , icon = icon
        , onFocusIn = createEntityActionMsg Entity.OnFocusIn
        , onKeyDownMsg = onKeyDownMsg
        , tabindexAV = tabindexAV
        }


forContext : Html.Attribute Msg -> Context.Model -> ViewModel
forContext tabindexAV context =
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
            , tabindexAV = tabindexAV
            }
    in
        create tabindexAV config context


forProject : Html.Attribute Msg -> Project.Model -> ViewModel
forProject tabindexAV project =
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
            , tabindexAV = tabindexAV
            }
    in
        create tabindexAV config project


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
