module Entity.ViewModel exposing (..)

import Context
import Dict
import Document
import EditMode exposing (EditMode)
import Entity exposing (Entity)
import Ext.Keyboard exposing (KeyboardEvent)
import Lazy
import Model exposing (EntityListViewType, GroupEntityType(ContextGroup, ProjectGroup), ViewType(..))
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


type alias GroupViewModel =
    { id : String
    , name : String
    , appHeader : { name : String, backgroundColor : String }
    , isDeleted : Bool
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
    }


create config entityModel =
    let
        id =
            Document.getId entityModel

        createEntityActionMsg =
            Msg.OnEntityAction (config.entityWrapper entityModel)

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
            createEntityActionMsg Entity.StartEditing
    in
        { id = id
        , name = name
        , isDeleted = Document.isDeleted entityModel
        , onActiveStateChanged =
            (\bool ->
                if bool then
                    Msg.SwitchView (config.getViewType id |> EntityListView)
                else
                    commonMsg.noOp
            )
        , startEditingMsg = startEditingMsg
        , onDeleteClicked = toggleDeleteMsg
        , onSaveClicked = createEntityActionMsg Entity.Save
        , onNameChanged = Entity.NameChanged >> createEntityActionMsg
        , onCancelClicked = Msg.DeactivateEditingMode
        , icon = icon
        , appHeader = appHeader
        , onFocusIn = createEntityActionMsg Entity.SetFocusedIn
        , onFocus = createEntityActionMsg Entity.SetFocused
        , onBlur = createEntityActionMsg Entity.SetBlurred
        , onKeyDownMsg = onKeyDownMsg
        }


contextGroup : Context.Model -> GroupViewModel
contextGroup context =
    let
        config : Config
        config =
            { groupByFn = Todo.getContextId
            , namePrefix = "@"
            , entityType = ContextGroup
            , entityWrapper = Entity.ContextEntity
            , nullEntity = Context.null
            , isNull = Context.isNull
            , nullIcon = { name = "inbox", color = inboxColor }
            , defaultIconName = "av:fiber-manual-record"
            , getViewType = Entity.ContextView
            }
    in
        create config context


projectGroup : Project.Model -> GroupViewModel
projectGroup project =
    let
        config : Config
        config =
            { groupByFn = Todo.getProjectId
            , namePrefix = "@"
            , entityType = ProjectGroup
            , entityWrapper = Entity.ProjectEntity
            , nullEntity = Project.null
            , isNull = Project.isNull
            , nullIcon = { name = "inbox", color = inboxColor }
            , defaultIconName = "av:fiber-manual-record"
            , getViewType = Entity.ProjectView
            }
    in
        create config project


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
