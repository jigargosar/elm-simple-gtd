module Update exposing (update)

import CommonMsg
import LocalPref
import Material
import Msg exposing (AppMsg(..))
import Notification
import Ports
import Return exposing (andThen, command)
import Update.AppDrawer
import Update.AppHeader
import Update.CustomSync
import Update.Entity
import Update.ExclusiveMode
import Update.Firebase
import Update.GroupDoc
import Update.LaunchBar
import Update.Subscription
import Update.Todo
import Update.ViewType
import X.Return exposing (returnWith, returnWithNow)
import Toolkit.Operators exposing (..)
import Types exposing (AppModel)
import Update.Config


--type alias ReturnF =
--    Return.ReturnF AppMsg AppModel
--
--
--type alias AndThenUpdate =
--    AppMsg -> ReturnF
--type alias UpdateConfig =
--    { --model
--      now : Time
--    , activeProjects : List ProjectDoc
--    , activeContexts : List ContextDoc
--    , updateEntityListCursorOnTodoChange : ReturnF
--    , updateEntityListCursorOnGroupDocChange : ReturnF
--    , currentViewEntityListLazy : Lazy (List Entity)
--
--    --msg
--    , clearSelection : ReturnF
--    , noop : ReturnF
--    , openLaunchBarMsg : ReturnF
--    , revertExclusiveMode : ReturnF
--    , setDomFocusToFocusInEntityCmd : ReturnF
--    , onSaveTodoForm : TodoForm -> ReturnF
--    , onSaveGroupDocForm : GroupDocForm -> ReturnF
--    , onSetExclusiveMode : ExclusiveMode -> ReturnF
--    , onSaveExclusiveModeForm : ReturnF
--    , onToggleContextArchived : DocId -> ReturnF
--    , onToggleContextDeleted : DocId -> ReturnF
--    , onToggleProjectArchived : DocId -> ReturnF
--    , onToggleProjectDeleted : DocId -> ReturnF
--    , switchToContextsView : ReturnF
--    , setFocusInEntityWithEntityId : EntityId -> ReturnF
--    , setFocusInEntity : Entity -> ReturnF
--    , closeNotification : String -> ReturnF
--    , onStartSetupAddTodo : ReturnF
--    , onSwitchToNewUserSetupModeIfNeeded : ReturnF
--    , onPersistLocalPref : ReturnF
--
--    -- todo msg
--    , afterTodoUpsert : TodoDoc -> ReturnF
--    , onStartAddingTodoWithFocusInEntityAsReference : ReturnF
--    , onStartAddingTodoToInbox : ReturnF
--    , onToggleTodoArchived : DocId -> ReturnF
--    , onToggleTodoDeleted : DocId -> ReturnF
--    , switchToEntityListView : EntityListViewType -> ReturnF
--    , onStartEditingTodo : TodoDoc -> ReturnF
--    }
--updateConfig : AndThenUpdate -> AppModel -> UpdateConfig
--update :    AndThenUpdate    -> AppMsg    -> ReturnF


update andThenUpdate msg =
    returnWith (Update.Config.updateConfig andThenUpdate)
        (updateInner # msg)



--updateInner : UpdateConfig -> AppMsg -> ReturnF


updateInner config msg =
    case msg of
        OnMdl msg_ ->
            andThen (Material.update OnMdl msg_)

        OnViewTypeMsg msg_ ->
            Update.ViewType.update config msg_

        OnPersistLocalPref ->
            Return.effect_ (LocalPref.encodeLocalPref >> Ports.persistLocalPref)

        OnCloseNotification tag ->
            command (Notification.closeNotification tag)

        OnCommonMsg msg_ ->
            CommonMsg.update msg_

        OnSubscriptionMsg msg_ ->
            Update.Subscription.update config msg_

        OnGroupDocMsg msg_ ->
            Update.GroupDoc.update msg_
                >> config.updateEntityListCursorOnGroupDocChange

        OnExclusiveModeMsg msg_ ->
            Update.ExclusiveMode.update config msg_

        OnAppHeaderMsg msg_ ->
            Update.AppHeader.update config msg_

        OnCustomSyncMsg msg_ ->
            Update.CustomSync.update config msg_

        OnEntityMsg msg_ ->
            Update.Entity.update config msg_

        OnLaunchBarMsgWithNow msg_ now ->
            Update.LaunchBar.update config now msg_

        OnLaunchBarMsg msg_ ->
            returnWithNow (OnLaunchBarMsgWithNow msg_)

        OnTodoMsg msg_ ->
            returnWithNow (OnTodoMsgWithNow msg_)

        OnTodoMsgWithNow msg_ now ->
            Update.Todo.update config now msg_
                >> config.updateEntityListCursorOnTodoChange

        OnFirebaseMsg msg_ ->
            Update.Firebase.update config msg_
                >> config.onPersistLocalPref

        OnAppDrawerMsg msg ->
            Update.AppDrawer.update msg
                >> config.onPersistLocalPref
