module Update.Subscription exposing (Config, update)

import Entity.Types exposing (..)
import ExclusiveMode.Types exposing (ExclusiveMode(XMNone))
import GroupDoc.Types exposing (..)
import Keyboard.Extra as KX exposing (Key)
import Model.GroupDocStore exposing (contextStore, projectStore)
import Model.Selection
import Model.Todo exposing (todoStore)
import Msg.Subscription exposing (SubscriptionMsg(..))
import Return
import Set
import Store
import Time exposing (Time)
import Todo.Types exposing (TodoDoc, TodoStore)
import X.Function.Infix exposing (..)
import X.Record exposing (..)
import X.Return exposing (..)


type alias SubModel model =
    { model
        | now : Time
        , todoStore : TodoStore
        , projectStore : ProjectStore
        , contextStore : ContextStore
        , editMode : ExclusiveMode
        , selectedEntityIdSet : Set.Set String
    }


type alias SubModelF model =
    SubModel model -> SubModel model


type alias SubReturn msg model =
    Return.Return msg (SubModel model)


type alias SubReturnF msg model =
    SubReturn msg model -> SubReturn msg model


type alias Config msg =
    { noop : msg
    , onStartAddingTodoToInbox : msg
    , onStartAddingTodoWithFocusInEntityAsReference : msg
    , openLaunchBarMsg : msg
    , revertExclusiveMode : msg
    , afterTodoUpsert : TodoDoc -> msg
    }


update :
    Config msg
    -> SubscriptionMsg
    -> SubReturnF msg model
update config msg =
    case msg of
        OnNowChanged now ->
            map (setNow now)

        OnGlobalKeyUp keyCode ->
            onGlobalKeyUp config (KX.fromCode keyCode)

        OnPouchDBChange dbName encodedDoc ->
            let
                afterEntityUpsertOnPouchDBChange ( entity, model ) =
                    map (\_ -> model)
                        >> returnMsgAsCmd
                            (case entity of
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


onGlobalKeyUp : Config msg -> Key -> SubReturnF msg model
onGlobalKeyUp config key =
    returnWith .editMode
        (\editMode ->
            case ( key, editMode ) of
                ( key, XMNone ) ->
                    let
                        clear =
                            map Model.Selection.clearSelection
                                >> returnMsgAsCmd config.revertExclusiveMode
                    in
                    case key of
                        KX.Escape ->
                            clear

                        KX.CharX ->
                            clear

                        KX.CharQ ->
                            returnMsgAsCmd config.onStartAddingTodoWithFocusInEntityAsReference

                        KX.CharI ->
                            returnMsgAsCmd config.onStartAddingTodoToInbox

                        KX.Slash ->
                            returnMsgAsCmd config.openLaunchBarMsg

                        _ ->
                            returnMsgAsCmd config.noop

                ( KX.Escape, _ ) ->
                    returnMsgAsCmd config.revertExclusiveMode

                _ ->
                    returnMsgAsCmd config.noop
        )



--setNow : Time -> SubModelF model


setNow now model =
    { model | now = now }



--updateKeyboardState : (KeyboardState -> KeyboardState) -> SubModelF model
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
