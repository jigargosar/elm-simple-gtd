port module Update exposing (update)

import AppDrawer.Main
import CommonMsg
import Lazy
import Model.EntityList
import Model.Stores
import Update.Entity
import Firebase.Main
import LaunchBar.Messages exposing (LaunchBarMsg)
import LocalPref
import Material
import Model
import Model.GroupDocStore
import Model.Selection
import Msg exposing (..)
import Msg.ViewType exposing (ViewTypeMsg(SwitchToContextsView))
import Time exposing (Time)
import Todo.Msg exposing (TodoMsg)
import Types exposing (AppModel)
import Update.AppHeader
import Update.CustomSync
import Update.ExclusiveMode
import Update.LaunchBar
import Update.Subscription
import Update.ViewType
import X.Return as Return exposing (returnWith, returnWithNow)
import Notification
import Return exposing (andThen, command, map)
import Update.Todo
import Json.Decode as D exposing (Decoder)
import Types exposing (..)
import Msg
import Update.GroupDoc


port persistLocalPref : D.Value -> Cmd msg


type alias ReturnF =
    Return.ReturnF AppMsg AppModel


type alias AndThenUpdate =
    AppMsg -> ReturnF


update :
    AndThenUpdate
    -> AppMsg
    -> ReturnF
update andThenUpdate msg =
    case msg of
        OnMdl msg_ ->
            andThen (Material.update OnMdl msg_)

        OnViewTypeMsg msg_ ->
            onViewTypeMsg andThenUpdate msg_

        OnPersistLocalPref ->
            Return.effect_ (LocalPref.encodeLocalPref >> persistLocalPref)

        OnCloseNotification tag ->
            command (Notification.closeNotification tag)

        -- non delegated
        OnCommonMsg msg_ ->
            CommonMsg.update msg_

        OnSubscriptionMsg msg_ ->
            Update.Subscription.update andThenUpdate msg_

        OnGroupDocMsg msg_ ->
            {- let
                   config : AppModel -> Update.GroupDoc.Config AppMsg AppModel
                   config oldModel =
                       { updateEntityListCursorOnGroupDocChange =
                           map (Stores.updateEntityListCursorOnGroupDocChange oldModel)
                       }
               in
            -}
            returnWith identity
                (\oldModel ->
                    Update.GroupDoc.update {- (config oldModel) -} msg_
                        >> map (Model.EntityList.updateEntityListCursorOnGroupDocChange oldModel)
                )

        OnExclusiveModeMsg msg_ ->
            let
                config : Update.ExclusiveMode.Config AppMsg AppModel
                config =
                    { focusEntityList = andThenUpdate Model.setDomFocusToFocusInEntityCmd
                    , saveTodoForm = Msg.onSaveTodoForm >> andThenUpdate
                    , saveGroupDocForm = Msg.onSaveGroupDocForm >> andThenUpdate
                    }
            in
                Update.ExclusiveMode.update config msg_

        OnAppHeaderMsg msg_ ->
            let
                config : Update.AppHeader.Config AppMsg AppModel
                config =
                    { setXMode = Msg.onSetExclusiveMode >> andThenUpdate
                    }
            in
                Update.AppHeader.update config msg_

        OnCustomSyncMsg msg_ ->
            let
                config : Update.CustomSync.Config AppMsg AppModel
                config =
                    { saveXModeForm = Msg.onSaveExclusiveModeForm |> andThenUpdate
                    , setXMode = Msg.onSetExclusiveMode >> andThenUpdate
                    }
            in
                Update.CustomSync.update config msg_

        OnEntityMsg msg_ ->
            Update.Entity.update andThenUpdate msg_

        OnLaunchBarMsgWithNow msg_ now ->
            onLaunchBarMsgWithNow andThenUpdate msg_ now

        OnLaunchBarMsg msg_ ->
            OnLaunchBarMsgWithNow msg_ |> returnWithNow

        OnTodoMsg msg_ ->
            returnWithNow (OnTodoMsgWithNow msg_)

        OnTodoMsgWithNow msg_ now ->
            onTodoMsgWithNow andThenUpdate msg_ now

        OnFirebaseMsg msg_ ->
            Firebase.Main.update andThenUpdate msg_

        OnAppDrawerMsg msg ->
            AppDrawer.Main.update andThenUpdate msg


onViewTypeMsg : AndThenUpdate -> ViewTypeMsg -> ReturnF
onViewTypeMsg andThenUpdate msg =
    let
        config : Update.ViewType.Config AppMsg AppModel
        config =
            { clearSelection = map Model.Selection.clearSelection }
    in
        Update.ViewType.update config msg


onLaunchBarMsgWithNow : AndThenUpdate -> LaunchBarMsg -> Time -> ReturnF
onLaunchBarMsgWithNow andThenUpdate msg now =
    let
        createConfig : AppModel -> Update.LaunchBar.Config AppMsg AppModel
        createConfig =
            (\m ->
                { now = now
                , activeProjects = (Model.GroupDocStore.getActiveProjects m)
                , activeContexts = (Model.GroupDocStore.getActiveContexts m)
                , onComplete = Msg.revertExclusiveMode |> andThenUpdate
                , setXMode = Msg.onSetExclusiveMode >> andThenUpdate
                , onSwitchView = Msg.switchToEntityListView >> andThenUpdate
                }
            )
    in
        returnWith
            createConfig
            (\config -> Update.LaunchBar.update config msg)


onTodoMsgWithNow : AndThenUpdate -> TodoMsg -> Time -> ReturnF
onTodoMsgWithNow andThenUpdate msg now =
    let
        config : AppModel -> Update.Todo.Config AppMsg AppModel
        config model =
            { switchToContextsView = Msg.switchToContextsViewMsg |> andThenUpdate
            , setFocusInEntityWithTodoId =
                (\todoId ->
                    -- todo: things concerning todoId should probably be moved into todo update module
                    map (Model.Stores.setFocusInEntityWithTodoId todoId)
                        >> andThenUpdate Model.setDomFocusToFocusInEntityCmd
                )
            , setFocusInEntity =
                (\entity ->
                    map (Model.setFocusInEntity entity)
                        >> andThenUpdate Model.setDomFocusToFocusInEntityCmd
                )
            , closeNotification = Msg.OnCloseNotification >> andThenUpdate
            , afterTodoUpdate = Msg.revertExclusiveMode |> andThenUpdate
            , setXMode = Msg.onSetExclusiveMode >> andThenUpdate
            , currentViewEntityList = Lazy.lazy (\_ -> Model.EntityList.createEntityListForCurrentView model)
            }
    in
        returnWith identity
            (\oldModel ->
                Update.Todo.update (config oldModel) now msg
                    >> map (Model.EntityList.updateEntityListCursorOnTodoChange oldModel)
            )
