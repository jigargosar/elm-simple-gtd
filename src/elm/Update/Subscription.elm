module Update.Subscription exposing (..)

import DomPorts exposing (focusSelectorIfNoFocusRCmd)
import Entity.Types exposing (..)
import ExclusiveMode.Types exposing (ExclusiveMode(XMNone))
import Model
import Model.GroupDocStore exposing (contextStore, projectStore)
import Model.Selection
import Model.Todo exposing (todoStore)
import Msg exposing (AppMsg(..), SubscriptionMsg(..))
import Todo.Msg
import Tuple2
import X.Function.Infix exposing (..)
import Return exposing (map)
import Time exposing (Time)
import Types exposing (..)
import X.Keyboard exposing (KeyboardState)
import X.Record exposing (maybeOverT2, over, overReturn)
import X.Return
import Keyboard.Extra as Key
import TodoMsg
import Msg
import Store


type alias AppModelF =
    AppModel -> AppModel


update andThenUpdate subMsg =
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
                            Todo.Msg.AfterUpsert model |> OnTodoMsg

                        _ ->
                            Msg.noop
            in
                X.Return.rAndThenMaybe
                    (upsertEncodedDocOnPouchDBChange dbName encodedDoc
                        >>? (Tuple2.mapEach afterEntityUpsertOnPouchDBChange Return.singleton
                                >> uncurry andThenUpdate
                            )
                    )

        OnFirebaseDatabaseChange dbName encodedDoc ->
            Return.effect_ (upsertEncodedDocOnFirebaseDatabaseChange dbName encodedDoc)


onGlobalKeyUp andThenUpdate key =
    X.Return.returnWith (.editMode)
        (\editMode ->
            case ( key, editMode ) of
                ( key, XMNone ) ->
                    let
                        clear =
                            map (Model.Selection.clearSelection)
                                >> andThenUpdate Msg.revertExclusiveMode
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
                    andThenUpdate Msg.revertExclusiveMode

                _ ->
                    identity
        )


setNow : Time -> AppModelF
setNow now model =
    { model | now = now }


keyboardState =
    X.Record.fieldLens .keyboardState (\s b -> { b | keyboardState = s })


updateKeyboardState : (KeyboardState -> KeyboardState) -> AppModelF
updateKeyboardState =
    over keyboardState



--upsertEncodedDocOnPouchDBChange : String -> E.Value -> AppModel -> Maybe ( Entity, AppModel )


upsertEncodedDocOnPouchDBChange dbName encodedEntity =
    case dbName of
        "todo-db" ->
            maybeOverT2 todoStore (Store.upsertOnPouchDBChange encodedEntity)
                >>? Tuple.mapFirst createTodoEntity

        "project-db" ->
            maybeOverT2 projectStore (Store.upsertOnPouchDBChange encodedEntity)
                >>? Tuple.mapFirst createProjectEntity

        "context-db" ->
            maybeOverT2 contextStore (Store.upsertOnPouchDBChange encodedEntity)
                >>? Tuple.mapFirst createContextEntity

        _ ->
            (\_ -> Nothing)



--upsertEncodedDocOnFirebaseDatabaseChange : String -> E.Value -> AppModel -> Cmd msg


upsertEncodedDocOnFirebaseDatabaseChange dbName encodedEntity =
    case dbName of
        "todo-db" ->
            .todoStore >> (Store.upsertInPouchDbOnFirebaseChange encodedEntity)

        "project-db" ->
            .projectStore >> (Store.upsertInPouchDbOnFirebaseChange encodedEntity)

        "context-db" ->
            .contextStore >> (Store.upsertInPouchDbOnFirebaseChange encodedEntity)

        _ ->
            (\_ -> Cmd.none)
