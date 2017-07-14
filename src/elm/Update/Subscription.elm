module Update.Subscription exposing (..)

import DomPorts exposing (focusSelectorIfNoFocusRCmd)
import Entity.Types exposing (Entity(TodoEntity))
import ExclusiveMode.Types exposing (ExclusiveMode(XMNone))
import Model
import Model.Selection
import Msg exposing (AppMsg(..), SubMsg(..))
import Stores
import Todo.Msg
import Tuple2
import X.Function.Infix exposing (..)
import Return exposing (map)
import Time exposing (Time)
import Types exposing (ModelF)
import X.Keyboard exposing (KeyboardState)
import X.Record exposing (over)
import X.Return
import Keyboard.Extra as Key
import TodoMsg
import Update.LaunchBar


onSubMsg andThenUpdate subMsg =
    case subMsg of
        OnNowChanged now ->
            map (setNow now)

        OnKeyboardMsg msg ->
            map (updateKeyboardState (X.Keyboard.update msg))
                >> focusSelectorIfNoFocusRCmd ".entity-list .focusable-list-item[tabindex=0]"

        OnGlobalKeyUp key ->
            onGlobalKeyUp andThenUpdate key

        OnPouchDBChange dbName encodedDoc ->
            let
                afterEntityUpsertOnPouchDBChange entity =
                    case entity of
                        TodoEntity model ->
                            Todo.Msg.Upsert model |> OnTodoMsg

                        _ ->
                            Model.noop
            in
                X.Return.andThenMaybe
                    (Stores.upsertEncodedDocOnPouchDBChange dbName encodedDoc
                        >>? (Tuple2.mapEach afterEntityUpsertOnPouchDBChange Return.singleton
                                >> uncurry andThenUpdate
                            )
                    )

        OnFirebaseDatabaseChange dbName encodedDoc ->
            Return.effect_ (Stores.upsertEncodedDocOnFirebaseChange dbName encodedDoc)


onGlobalKeyUp andThenUpdate key =
    X.Return.with (.editMode)
        (\editMode ->
            case ( key, editMode ) of
                ( key, XMNone ) ->
                    let
                        clear =
                            map (Model.Selection.clearSelection)
                                >> andThenUpdate OnDeactivateEditingMode
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
                                Update.LaunchBar.open andThenUpdate

                            _ ->
                                identity

                ( Key.Escape, _ ) ->
                    andThenUpdate OnDeactivateEditingMode

                _ ->
                    identity
        )


setNow : Time -> ModelF
setNow now model =
    { model | now = now }


keyboardState =
    X.Record.field .keyboardState (\s b -> { b | keyboardState = s })


updateKeyboardState : (KeyboardState -> KeyboardState) -> ModelF
updateKeyboardState =
    over keyboardState
