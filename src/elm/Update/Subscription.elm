module Update.Subscription exposing (..)

import DomPorts exposing (focusSelectorIfNoFocusRCmd)
import Entity.Types exposing (Entity(TodoEntity))
import ExclusiveMode.Types exposing (ExclusiveMode(XMNone))
import Keyboard.Combo
import Model
import Model.Selection
import Msg exposing (AppMsg(..), SubscriptionMsg(..))
import Stores
import Todo.Msg
import Tuple2
import X.Function.Infix exposing (..)
import Return exposing (map)
import Time exposing (Time)
import ReturnTypes exposing (..)
import X.Keyboard exposing (KeyboardState)
import X.Record exposing (over, overReturn)
import X.Return
import Keyboard.Extra as Key
import TodoMsg
import XMMsg


update andThenUpdate subMsg =
    case subMsg of
        OnNowChanged now ->
            map (setNow now)

        OnKeyboardMsg msg ->
            map (updateKeyboardState (X.Keyboard.update msg))
                >> focusSelectorIfNoFocusRCmd ".entity-list .focusable-list-item[tabindex=0]"

        OnGlobalKeyUp key ->
            onGlobalKeyUp andThenUpdate key

        OnKeyCombo comboMsg ->
            Return.andThen (updateKeyCombo comboMsg)

        OnPouchDBChange dbName encodedDoc ->
            let
                afterEntityUpsertOnPouchDBChange entity =
                    case entity of
                        TodoEntity model ->
                            Todo.Msg.Upsert model |> OnTodoMsg

                        _ ->
                            Model.noop
            in
                X.Return.rAndThenMaybe
                    (Stores.upsertEncodedDocOnPouchDBChange dbName encodedDoc
                        >>? (Tuple2.mapEach afterEntityUpsertOnPouchDBChange Return.singleton
                                >> uncurry andThenUpdate
                            )
                    )

        OnFirebaseDatabaseChange dbName encodedDoc ->
            Return.effect_ (Stores.upsertEncodedDocOnFirebaseDatabaseChange dbName encodedDoc)


onGlobalKeyUp andThenUpdate key =
    X.Return.returnWith (.editMode)
        (\editMode ->
            case ( key, editMode ) of
                ( key, XMNone ) ->
                    let
                        clear =
                            map (Model.Selection.clearSelection)
                                >> andThenUpdate XMMsg.onSetExclusiveModeToNoneAndTryRevertingFocus
                    in
                        case key of
                            Key.Escape ->
                                clear

                            Key.CharX ->
                                clear

                            Key.CharQ ->
                                andThenUpdate TodoMsg.onStartAddingTodoWithFocusInEntityAsReference

                            Key.CharI ->
                                andThenUpdate TodoMsg.onStartAddingTodoToInbox

                            Key.Slash ->
                                andThenUpdate Msg.openLaunchBarMsg

                            _ ->
                                identity

                ( Key.Escape, _ ) ->
                    andThenUpdate XMMsg.onSetExclusiveModeToNoneAndTryRevertingFocus

                _ ->
                    identity
        )


setNow : Time -> ModelF
setNow now model =
    { model | now = now }


keyboardState =
    X.Record.fieldLens .keyboardState (\s b -> { b | keyboardState = s })


updateKeyboardState : (KeyboardState -> KeyboardState) -> ModelF
updateKeyboardState =
    over keyboardState


keyComboModel =
    X.Record.fieldLens .keyComboModel (\s b -> { b | keyComboModel = s })


updateKeyCombo : Keyboard.Combo.Msg -> ModelReturnF
updateKeyCombo comboMsg =
    overReturn
        keyComboModel
        (Keyboard.Combo.update comboMsg)
