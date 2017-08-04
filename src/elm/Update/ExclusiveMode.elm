module Update.ExclusiveMode exposing (..)

import DomPorts
import ExclusiveMode.Types exposing (ExclusiveMode(..))
import GroupDoc exposing (..)
import Return
import Todo.FormTypes exposing (..)
import X.Record exposing (..)
import X.Return exposing (..)


type ExclusiveModeMsg
    = OnSetExclusiveMode ExclusiveMode
    | OnSetExclusiveModeToNoneAndTryRevertingFocus
    | OnSaveExclusiveModeForm


type alias SubModel model =
    { model
        | editMode : ExclusiveMode
    }


type alias SubReturn msg model =
    Return.Return msg (SubModel model)


type alias SubReturnF msg model =
    SubReturn msg model -> SubReturn msg model


type alias Config msg a =
    { a
        | saveTodoForm : TodoForm -> msg
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
            let
                _ =
                    Debug.log "revertExclusiveMode-focus-entity-list" ()

                setDomFocusToFocusInEntityCmd =
                    DomPorts.focusSelector ".entity-list .focusable-list-item[tabindex=0]"
            in
            map setExclusiveModeToNone
                >> command setDomFocusToFocusInEntityCmd

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

        _ ->
            identity
