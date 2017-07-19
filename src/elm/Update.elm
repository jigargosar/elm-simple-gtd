module Update exposing (update)

import Update.AppDrawer
import CommonMsg
import Model.GroupDocStore
import Ports
import Update.Firebase
import LocalPref
import Material
import Update.AppHeader
import Update.ExclusiveMode
import Update.LaunchBar
import Update.Subscription
import X.Return as Return exposing (returnWith, returnWithNow)
import Notification
import Return exposing (andThen, command, map)
import Toolkit.Operators exposing (..)
import Lazy
import Model.EntityList
import Model.Stores
import TodoMsg
import Update.Entity
import Model
import Model.GroupDocStore
import Model.Selection
import Msg exposing (..)
import Update.CustomSync
import Update.ViewType
import Update.Todo
import Types exposing (..)
import Update.GroupDoc


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
            let
                config : Update.ViewType.Config AppMsg AppModel
                config =
                    { clearSelection = map Model.Selection.clearSelection }
            in
                Update.ViewType.update config msg_

        OnPersistLocalPref ->
            Return.effect_ (LocalPref.encodeLocalPref >> Ports.persistLocalPref)

        OnCloseNotification tag ->
            command (Notification.closeNotification tag)

        OnCommonMsg msg_ ->
            CommonMsg.update msg_

        OnSubscriptionMsg msg_ ->
            let
                config : Update.Subscription.Config AppMsg AppModel
                config =
                    { noop = andThenUpdate Msg.noop
                    , onStartAddingTodoToInbox =
                        andThenUpdate TodoMsg.onStartAddingTodoToInbox
                    , onStartAddingTodoWithFocusInEntityAsReference =
                        andThenUpdate
                            TodoMsg.onStartAddingTodoWithFocusInEntityAsReference
                    , openLaunchBarMsg = andThenUpdate Msg.openLaunchBarMsg
                    , revertExclusiveMode = andThenUpdate Msg.revertExclusiveMode
                    , afterTodoUpsert = TodoMsg.afterTodoUpsert >> andThenUpdate
                    }
            in
                Update.Subscription.update config msg_

        OnGroupDocMsg msg_ ->
            returnWith identity
                (\oldModel ->
                    Update.GroupDoc.update msg_
                        >> map (Model.EntityList.updateEntityListCursorOnGroupDocChange oldModel)
                )

        OnExclusiveModeMsg msg_ ->
            let
                config : Update.ExclusiveMode.Config AppMsg AppModel
                config =
                    { focusEntityList = andThenUpdate Msg.setDomFocusToFocusInEntityCmd
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
            let
                config : Update.Entity.Config AppMsg AppModel
                config =
                    { onSetExclusiveMode = Msg.onSetExclusiveMode >> andThenUpdate
                    , revertExclusiveMode = Msg.revertExclusiveMode |> andThenUpdate
                    , onToggleContextArchived = Msg.onToggleContextArchived >> andThenUpdate
                    , onToggleContextDeleted = Msg.onToggleContextDeleted >> andThenUpdate
                    , onToggleProjectArchived = Msg.onToggleProjectArchived >> andThenUpdate
                    , onToggleProjectDeleted = Msg.onToggleProjectDeleted >> andThenUpdate
                    , onToggleTodoArchived = TodoMsg.onToggleDoneAndMaybeSelection >> andThenUpdate
                    , onToggleTodoDeleted = TodoMsg.onToggleDeletedAndMaybeSelection >> andThenUpdate
                    , switchToEntityListView = Msg.switchToEntityListView >> andThenUpdate
                    , setDomFocusToFocusInEntityCmd =
                        Msg.setDomFocusToFocusInEntityCmd |> andThenUpdate
                    , onStartEditingTodo = TodoMsg.onStartEditingTodo >> andThenUpdate
                    }
            in
                Update.Entity.update config msg_

        OnLaunchBarMsgWithNow msg_ now ->
            let
                createConfig : AppModel -> Update.LaunchBar.Config AppMsg AppModel
                createConfig model =
                    { now = now
                    , activeProjects = (Model.GroupDocStore.getActiveProjects model)
                    , activeContexts = (Model.GroupDocStore.getActiveContexts model)
                    , onComplete = Msg.revertExclusiveMode |> andThenUpdate
                    , setXMode = Msg.onSetExclusiveMode >> andThenUpdate
                    , onSwitchView = Msg.switchToEntityListView >> andThenUpdate
                    }
            in
                returnWith
                    (createConfig)
                    (Update.LaunchBar.update # msg_)

        OnLaunchBarMsg msg_ ->
            returnWithNow (OnLaunchBarMsgWithNow msg_)

        OnTodoMsg msg_ ->
            returnWithNow (OnTodoMsgWithNow msg_)

        OnTodoMsgWithNow msg_ now ->
            let
                config : AppModel -> Update.Todo.Config AppMsg AppModel
                config model =
                    { switchToContextsView = Msg.switchToContextsViewMsg |> andThenUpdate
                    , setFocusInEntityWithEntityId =
                        -- later: create and move focusInEntity related methods to corresponding update
                        (\entityId ->
                            map (Model.Stores.setFocusInEntityWithEntityId entityId)
                                >> andThenUpdate Msg.setDomFocusToFocusInEntityCmd
                        )
                    , setFocusInEntity =
                        (\entity ->
                            map (Model.setFocusInEntity entity)
                                >> andThenUpdate Msg.setDomFocusToFocusInEntityCmd
                        )
                    , closeNotification = Msg.OnCloseNotification >> andThenUpdate
                    , afterTodoUpdate = Msg.revertExclusiveMode |> andThenUpdate
                    , setXMode = Msg.onSetExclusiveMode >> andThenUpdate
                    , currentViewEntityList = Lazy.lazy (\_ -> Model.EntityList.createEntityListForCurrentView model)
                    }
            in
                returnWith identity
                    (\oldModel ->
                        Update.Todo.update (config oldModel) now msg_
                            >> map (Model.EntityList.updateEntityListCursorOnTodoChange oldModel)
                    )

        OnFirebaseMsg msg_ ->
            let
                config : Update.Firebase.Config AppMsg AppModel
                config =
                    { onStartSetupAddTodo = andThenUpdate TodoMsg.onStartSetupAddTodo
                    , revertExclusiveMode = andThenUpdate Msg.revertExclusiveMode
                    , onSetExclusiveMode = Msg.onSetExclusiveMode >> andThenUpdate
                    , onSwitchToNewUserSetupModeIfNeeded =
                        andThenUpdate Msg.onSwitchToNewUserSetupModeIfNeeded
                    }
            in
                Update.Firebase.update config msg_
                    >> andThenUpdate Msg.OnPersistLocalPref

        OnAppDrawerMsg msg ->
            Update.AppDrawer.update msg
                >> andThenUpdate Msg.OnPersistLocalPref
