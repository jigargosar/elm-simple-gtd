module Update.ExclusiveMode exposing (Config, update)

import ExclusiveMode.Types exposing (ExclusiveMode(..))
import Msg.ExclusiveMode exposing (ExclusiveModeMsg(..))
import Return
import Todo.FormTypes exposing (..)
import Types.GroupDoc exposing (..)
import X.Record exposing (..)
import X.Return exposing (..)


type alias SubModel model =
    { model
        | editMode : ExclusiveMode
        , pouchDBRemoteSyncURI : String
    }


type alias SubReturn msg model =
    Return.Return msg (SubModel model)


type alias SubReturnF msg model =
    SubReturn msg model -> SubReturn msg model


type alias Config msg a =
    { a
        | setDomFocusToFocusInEntityCmd : msg
        , saveTodoForm : TodoForm -> msg
        , saveGroupDocForm : GroupDocForm -> msg
    }


update :
    Config msg a
    -> ExclusiveModeMsg
    -> SubReturnF msg model
update config msg =
    case msg of
        OnSetExclusiveMode mode ->
            setExclusiveMode mode |> map

        OnSetExclusiveModeToNoneAndTryRevertingFocus ->
            map setExclusiveModeToNone
                >> returnMsgAsCmd config.setDomFocusToFocusInEntityCmd

        OnSaveExclusiveModeForm ->
            onSaveExclusiveModeForm config


exclusiveMode =
    fieldLens .editMode (\s b -> { b | editMode = s })


onSaveExclusiveModeForm : Config msg a -> SubReturnF msg model
onSaveExclusiveModeForm config =
    returnWith .editMode (saveExclusiveModeForm config)
        >> update config OnSetExclusiveModeToNoneAndTryRevertingFocus


setExclusiveMode =
    set exclusiveMode


setExclusiveModeToNone =
    setExclusiveMode XMNone


saveExclusiveModeForm : Config msg a -> ExclusiveMode -> SubReturnF msg model
saveExclusiveModeForm config exMode =
    case exMode of
        XMGroupDocForm form ->
            config.saveGroupDocForm form |> returnMsgAsCmd

        XMTodoForm form ->
            config.saveTodoForm form |> returnMsgAsCmd

        XMCustomSync form ->
            (\model -> { model | pouchDBRemoteSyncURI = form.uri })
                |> map

        _ ->
            identity
