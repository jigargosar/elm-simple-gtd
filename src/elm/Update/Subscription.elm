module Update.Subscription exposing (..)

import Data.TodoDoc exposing (..)
import Document exposing (DocId)
import Entity exposing (..)
import ExclusiveMode.Types exposing (ExclusiveMode)
import GroupDoc exposing (..)
import Json.Encode as E
import Keyboard
import Keyboard.Extra as KX exposing (Key(..))
import Models.GroupDocStore exposing (contextStore, projectStore)
import Models.Selection
import Models.Todo exposing (todoStore)
import Ports
import Return
import Set exposing (Set)
import Store
import X.Function.Infix exposing (..)
import X.Record exposing (..)
import X.Return exposing (..)


type SubscriptionMsg
    = OnPouchDBChange String E.Value
    | OnFirebaseDatabaseChange String E.Value
    | OnGlobalKeyUp Int
    | OnGlobalKeyDown Int


subscriptions =
    Sub.batch
        [ Ports.pouchDBChanges (uncurry OnPouchDBChange)
        , Ports.onFirebaseDatabaseChange (uncurry OnFirebaseDatabaseChange)
        , Keyboard.ups OnGlobalKeyUp
        , Keyboard.downs OnGlobalKeyDown
        ]


type alias SubModel model =
    { model
        | todoStore : TodoStore
        , projectStore : ProjectStore
        , contextStore : ContextStore
        , selectedEntityIdSet : Set DocId
        , editMode : ExclusiveMode
    }


type alias SubModelF model =
    SubModel model -> SubModel model


type alias SubReturn msg model =
    Return.Return msg (SubModel model)


type alias SubReturnF msg model =
    SubReturn msg model -> SubReturn msg model


type alias Config msg a =
    { a
        | onStartAddingTodoToInbox : msg
        , onStartAddingTodoWithFocusInEntityAsReference : msg
        , revertExclusiveMode : msg
        , focusNextEntityMsgNew : msg
        , focusPrevEntityMsgNew : msg
    }



--update : Config msg a -> SubscriptionMsg -> SubReturnF msg model


update config msg =
    case msg of
        OnPouchDBChange dbName encodedDoc ->
            onPouchDBChange config dbName encodedDoc

        OnFirebaseDatabaseChange dbName encodedDoc ->
            onFirebaseDatabaseChange dbName encodedDoc

        OnGlobalKeyUp keyCode ->
            onGlobalKeyUp config keyCode

        OnGlobalKeyDown keyCode ->
            onGlobalKeyDown config keyCode


onFirebaseDatabaseChange dbName encodedDoc =
    effect (upsertEncodedDocOnFirebaseDatabaseChange dbName encodedDoc)


onGlobalKeyDown config keyCode =
    let
        key =
            KX.fromCode keyCode

        onEditModeNone =
            case key of
                ArrowUp ->
                    returnMsgAsCmd config.focusPrevEntityMsgNew

                ArrowDown ->
                    returnMsgAsCmd config.focusNextEntityMsgNew

                _ ->
                    identity
    in
    (\editMode ->
        case editMode of
            ExclusiveMode.Types.XMNone ->
                onEditModeNone

            _ ->
                identity
    )
        |> returnWith .editMode


onGlobalKeyUp config keyCode =
    let
        key =
            KX.fromCode keyCode

        clear =
            map Models.Selection.clearSelection
                >> returnMsgAsCmd config.revertExclusiveMode

        onEditModeNone =
            case key of
                Escape ->
                    clear

                CharX ->
                    clear

                CharQ ->
                    returnMsgAsCmd
                        config.onStartAddingTodoWithFocusInEntityAsReference

                CharI ->
                    returnMsgAsCmd config.onStartAddingTodoToInbox

                _ ->
                    identity
    in
    (\exMode ->
        case ( key, exMode ) of
            ( _, ExclusiveMode.Types.XMNone ) ->
                onEditModeNone

            ( Escape, _ ) ->
                returnMsgAsCmd config.revertExclusiveMode

            _ ->
                identity
    )
        |> returnWith .editMode


onPouchDBChange config dbName encodedDoc =
    let
        afterEntityUpsertOnPouchDBChange ( entity, model ) =
            map (\_ -> model)
                >> (case entity of
                        TodoEntity todo ->
                            identity

                        _ ->
                            identity
                   )
    in
    X.Return.returnWithMaybe2 identity
        (upsertEncodedDocOnPouchDBChange dbName encodedDoc >>? afterEntityUpsertOnPouchDBChange)


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
