module Update.Subscription exposing (Config, update)

import DomPorts exposing (focusSelectorIfNoFocusRCmd)
import Entity.Types exposing (..)
import ExclusiveMode.Types exposing (ExclusiveMode(XMNone))
import GroupDoc.Types exposing (..)
import Keyboard.Extra as KX
import Model.GroupDocStore exposing (contextStore, projectStore)
import Model.Selection
import Model.Todo exposing (todoStore)
import Msg.Subscription exposing (SubscriptionMsg(..))
import Return exposing (map)
import Set
import Store
import Time exposing (Time)
import Todo.Types exposing (TodoDoc, TodoStore)
import X.Function.Infix exposing (..)
import X.Keyboard exposing (KeyboardState)
import X.Record exposing (..)
import X.Return exposing (rAndThenMaybe, returnWith)


type alias SubModel model =
    { model
        | now : Time
        , todoStore : TodoStore
        , projectStore : ProjectStore
        , contextStore : ContextStore
        , editMode : ExclusiveMode
        , selectedEntityIdSet : Set.Set String
        , keyboardState : KeyboardState
    }


type alias SubModelF model =
    SubModel model -> SubModel model


type alias SubReturn msg model =
    Return.Return msg (SubModel model)


type alias SubReturnF msg model =
    SubReturn msg model -> SubReturn msg model


type alias Config msg model =
    { noop : SubReturnF msg model
    , onStartAddingTodoToInbox : SubReturnF msg model
    , onStartAddingTodoWithFocusInEntityAsReference : SubReturnF msg model
    , openLaunchBarMsg : SubReturnF msg model
    , revertExclusiveMode : SubReturnF msg model
    , afterTodoUpsert : TodoDoc -> SubReturnF msg model
    }


update :
    Config msg model
    -> SubscriptionMsg
    -> SubReturnF msg model
update config msg =
    case msg of
        OnNowChanged now ->
            map (setNow now)

        OnKeyboardMsg msg ->
            map (updateKeyboardState (KX.update msg))
                >> focusSelectorIfNoFocusRCmd ".entity-list .focusable-list-item[tabindex=0]"

        OnGlobalKeyUp key ->
            onGlobalKeyUp config key

        OnPouchDBChange dbName encodedDoc ->
            let
                afterEntityUpsertOnPouchDBChange ( entity, model ) =
                    map (\_ -> model)
                        >> (case entity of
                                TodoEntity todo ->
                                    config.afterTodoUpsert todo

                                _ ->
                                    config.noop
                           )
            in
            X.Return.returnWithMaybe2 identity
                (upsertEncodedDocOnPouchDBChange dbName encodedDoc >>? afterEntityUpsertOnPouchDBChange)

        OnFirebaseDatabaseChange dbName encodedDoc ->
            Return.effect_ (upsertEncodedDocOnFirebaseDatabaseChange dbName encodedDoc)



--onGlobalKeyUp : Config msg model -> Key -> SubReturnF msg model


onGlobalKeyUp config key =
    returnWith .editMode
        (\editMode ->
            case ( key, editMode ) of
                ( key, XMNone ) ->
                    let
                        clear =
                            map Model.Selection.clearSelection
                                >> config.revertExclusiveMode
                    in
                    case key of
                        KX.Escape ->
                            clear

                        KX.CharX ->
                            clear

                        KX.CharQ ->
                            config.onStartAddingTodoWithFocusInEntityAsReference

                        KX.CharI ->
                            config.onStartAddingTodoToInbox

                        KX.Slash ->
                            config.openLaunchBarMsg

                        _ ->
                            identity

                ( KX.Escape, _ ) ->
                    config.revertExclusiveMode

                _ ->
                    identity
        )



--setNow : Time -> SubModelF model


setNow now model =
    { model | now = now }


keyboardState =
    fieldLens .keyboardState (\s b -> { b | keyboardState = s })



--updateKeyboardState : (KeyboardState -> KeyboardState) -> SubModelF model


updateKeyboardState =
    over keyboardState



--upsertEncodedDocOnPouchDBChange : String -> E.Value -> SubModel model -> Maybe ( Entity, SubModel model )


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
            \_ -> Nothing



--upsertEncodedDocOnFirebaseDatabaseChange : String -> E.Value -> SubModel model -> Cmd msg


upsertEncodedDocOnFirebaseDatabaseChange dbName encodedEntity =
    case dbName of
        "todo-db" ->
            .todoStore >> Store.upsertInPouchDbOnFirebaseChange encodedEntity

        "project-db" ->
            .projectStore >> Store.upsertInPouchDbOnFirebaseChange encodedEntity

        "context-db" ->
            .contextStore >> Store.upsertInPouchDbOnFirebaseChange encodedEntity

        _ ->
            \_ -> Cmd.none
