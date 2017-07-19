module Update.ExclusiveMode exposing (Config, update)

import ExclusiveMode.Types exposing (ExclusiveMode(..))
import GroupDoc.FormTypes exposing (GroupDocForm, GroupDocFormMode(GDFM_Add, GDFM_Edit))
import Msg.ExclusiveMode exposing (ExclusiveModeMsg(..))
import Return exposing (andThen, map)
import Todo.FormTypes exposing (..)
import X.Record exposing (..)
import X.Return exposing (returnWith)


type alias SubModel model =
    { model
        | editMode : ExclusiveMode
        , pouchDBRemoteSyncURI : String
    }


type alias SubReturn msg model =
    Return.Return msg (SubModel model)


type alias SubReturnF msg model =
    SubReturn msg model -> SubReturn msg model


type alias Config a msg model =
    { a
        | setDomFocusToFocusInEntityCmd : SubReturnF msg model
        , onSaveTodoForm : TodoForm -> SubReturnF msg model
        , onSaveGroupDocForm : GroupDocForm -> SubReturnF msg model
    }


update :
    Config a msg model
    -> ExclusiveModeMsg
    -> SubReturnF msg model
update config msg =
    case msg of
        OnSetExclusiveMode mode ->
            setExclusiveMode mode |> map

        OnSetExclusiveModeToNoneAndTryRevertingFocus ->
            map setExclusiveModeToNone
                >> config.setDomFocusToFocusInEntityCmd

        OnSaveExclusiveModeForm ->
            onSaveExclusiveModeForm config


exclusiveMode =
    fieldLens .editMode (\s b -> { b | editMode = s })


onSaveExclusiveModeForm : Config a msg model -> SubReturnF msg model
onSaveExclusiveModeForm config =
    returnWith .editMode (saveExclusiveModeForm config)
        >> update config OnSetExclusiveModeToNoneAndTryRevertingFocus


setExclusiveMode =
    set exclusiveMode


setExclusiveModeToNone =
    setExclusiveMode XMNone


saveExclusiveModeForm : Config a msg model -> ExclusiveMode -> SubReturnF msg model
saveExclusiveModeForm config exMode =
    case exMode of
        XMGroupDocForm form ->
            config.onSaveGroupDocForm form

        XMTodoForm form ->
            config.onSaveTodoForm form

        XMCustomSync form ->
            (\model -> { model | pouchDBRemoteSyncURI = form.uri })
                |> map

        _ ->
            identity
