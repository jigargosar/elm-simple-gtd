module Update.Subscription exposing (..)

import Entity.Types exposing (..)
import ExclusiveMode.Types exposing (ExclusiveMode(XMNone))
import Keyboard.Extra as KX exposing (Key)
import Models.GroupDocStore exposing (contextStore, projectStore)
import Models.Selection
import Models.Todo exposing (todoStore)
import Return
import Set
import Store
import Time exposing (Time)
import Types.GroupDoc exposing (..)
import Types.Todo exposing (..)
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


type alias Config msg a =
    { a
        | onStartAddingTodoToInbox : msg
        , onStartAddingTodoWithFocusInEntityAsReference : msg
        , openLaunchBarMsg : msg
        , revertExclusiveMode : msg
        , afterTodoUpsert : TodoDoc -> msg
        , onGotoRunningTodoMsg : msg
        , entityListFocusPreviousEntityMsg : msg
        , entityListFocusNextEntityMsg : msg
    }


onNowChanged now =
    map (setNow now)


onPouchDBChange config dbName encodedDoc =
    let
        afterEntityUpsertOnPouchDBChange ( entity, model ) =
            map (\_ -> model)
                >> (case entity of
                        TodoEntity todo ->
                            config.afterTodoUpsert todo |> returnMsgAsCmd

                        _ ->
                            identity
                   )
    in
    X.Return.returnWithMaybe2 identity
        (upsertEncodedDocOnPouchDBChange dbName encodedDoc >>? afterEntityUpsertOnPouchDBChange)


onGlobalKeyDown config key =
    returnWith .editMode
        (\editMode ->
            case ( key, editMode ) of
                ( key, XMNone ) ->
                    case key of
                        KX.ArrowUp ->
                            returnMsgAsCmd
                                config.entityListFocusPreviousEntityMsg

                        KX.ArrowDown ->
                            returnMsgAsCmd
                                config.entityListFocusNextEntityMsg

                        _ ->
                            identity

                _ ->
                    identity
        )


onGlobalKeyUp : Config msg a -> Key -> SubReturnF msg model
onGlobalKeyUp config key =
    returnWith .editMode
        (\editMode ->
            case ( key, editMode ) of
                ( key, XMNone ) ->
                    let
                        clear =
                            map Models.Selection.clearSelection
                                >> returnMsgAsCmd config.revertExclusiveMode
                    in
                    case key of
                        KX.Escape ->
                            clear

                        KX.CharX ->
                            clear

                        KX.CharQ ->
                            returnMsgAsCmd
                                config.onStartAddingTodoWithFocusInEntityAsReference

                        KX.CharI ->
                            returnMsgAsCmd config.onStartAddingTodoToInbox

                        KX.Slash ->
                            returnMsgAsCmd config.openLaunchBarMsg

                        KX.CharT ->
                            returnMsgAsCmd config.onGotoRunningTodoMsg

                        _ ->
                            identity

                ( KX.Escape, _ ) ->
                    returnMsgAsCmd config.revertExclusiveMode

                _ ->
                    identity
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
