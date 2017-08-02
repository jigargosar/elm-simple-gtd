module Update.Subscription exposing (..)

import Entity exposing (..)
import ExclusiveMode.Types
import GroupDoc exposing (..)
import Keyboard.Extra exposing (Key(..))
import Models.GroupDocStore exposing (contextStore, projectStore)
import Models.Selection
import Models.Todo exposing (todoStore)
import Return
import Store
import Todo exposing (..)
import X.Function.Infix exposing (..)
import X.Record exposing (..)
import X.Return exposing (..)


type alias SubModel model =
    { model
        | todoStore : TodoStore
        , projectStore : ProjectStore
        , contextStore : ContextStore
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


onGlobalKeyDown config key =
    let
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


onGlobalKeyUp config key =
    let
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
    (\editMode ->
        case ( key, editMode ) of
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
