module Update.ExclusiveMode exposing (..)

import Context
import Document.Types exposing (getDocId)
import Entity.Types exposing (..)
import ExclusiveMode.Types exposing (ExclusiveMode(..))
import GroupDoc
import GroupDoc.FormTypes exposing (GroupDocFormMode(GDFM_Add, GDFM_Edit))
import GroupDoc.Types exposing (ContextStore, GroupDocType(..), ProjectStore)
import Msg.ExclusiveMode exposing (ExclusiveModeMsg(..))
import Return exposing (andThen, map)
import Stores
import Time exposing (Time)
import Todo
import Todo.FormTypes exposing (..)
import Todo.Types exposing (..)
import ViewType exposing (ViewType)
import X.Record exposing (..)
import X.Return exposing (returnWith)


type alias SubModel model =
    { model
        | editMode : ExclusiveMode
        , todoStore : TodoStore
        , projectStore : ProjectStore
        , contextStore : ContextStore
        , pouchDBRemoteSyncURI : String
        , now : Time
        , focusInEntity : Entity
        , mainViewType : ViewType
    }


type alias SubReturn msg model =
    Return.Return msg (SubModel model)


type alias SubReturnF msg model =
    SubReturn msg model -> SubReturn msg model


type alias Config msg model =
    { focusEntityList : SubReturnF msg model
    , saveTodoForm : TodoForm -> SubReturnF msg model
    }


update :
    Config msg model
    -> ExclusiveModeMsg
    -> SubReturnF msg model
update config msg =
    case msg of
        OnSetExclusiveMode mode ->
            setExclusiveMode mode |> map

        OnSetExclusiveModeToNoneAndTryRevertingFocus ->
            map setExclusiveModeToNone
                >> config.focusEntityList

        OnSaveExclusiveModeForm ->
            onSaveExclusiveModeForm config


exclusiveMode =
    fieldLens .editMode (\s b -> { b | editMode = s })


onSaveExclusiveModeForm : Config msg model -> SubReturnF msg model
onSaveExclusiveModeForm config =
    returnWith .editMode (saveExclusiveModeForm config)
        >> update config OnSetExclusiveModeToNoneAndTryRevertingFocus


setExclusiveMode =
    set exclusiveMode


setExclusiveModeToNone =
    setExclusiveMode XMNone


saveExclusiveModeForm : Config msg model -> ExclusiveMode -> SubReturnF msg model
saveExclusiveModeForm config exMode =
    case exMode of
        XMGroupDocForm form ->
            -- todo: cleanup and move
            let
                update fn =
                    fn form.id (GroupDoc.setName form.name)
                        |> andThen
            in
                case form.groupDocType of
                    ContextGroupDoc ->
                        case form.mode of
                            GDFM_Add ->
                                Stores.insertContext form.name

                            GDFM_Edit ->
                                update Stores.updateContext

                    ProjectGroupDoc ->
                        case form.mode of
                            GDFM_Add ->
                                Stores.insertProject form.name

                            GDFM_Edit ->
                                update Stores.updateProject

        XMTodoForm form ->
            config.saveTodoForm form

        XMCustomSync form ->
            (\model -> { model | pouchDBRemoteSyncURI = form.uri })
                |> map

        _ ->
            identity
