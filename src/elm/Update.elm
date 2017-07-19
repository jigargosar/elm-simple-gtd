module Update exposing (update)

import CommonMsg
import Document.Types exposing (..)
import Entity.Types exposing (..)
import ExclusiveMode.Types exposing (ExclusiveMode)
import GroupDoc.FormTypes exposing (GroupDocForm)
import GroupDoc.Types exposing (..)
import Lazy exposing (Lazy)
import LocalPref
import Material
import Model
import Model.EntityList
import Model.GroupDocStore
import Model.Selection
import Model.Stores
import Msg exposing (AppMsg(..))
import Notification
import Ports
import Return exposing (andThen, command, map)
import Time exposing (Time)
import Todo.FormTypes exposing (..)
import Todo.Types exposing (TodoDoc)
import TodoMsg
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


type alias ReturnF =
    Return.ReturnF AppMsg AppModel


type alias AndThenUpdate =
    AppMsg -> ReturnF



{-
   update :
       (AppMsg -> Return.ReturnF AppMsg AppModel)
       -> AppMsg
       -> Return.ReturnF AppMsg AppModel
-}


type alias UpdateConfig =
    { --model
      now : Time
    , activeProjects : List ProjectDoc
    , activeContexts : List ContextDoc
    , updateEntityListCursorOnTodoChange : ReturnF
    , updateEntityListCursorOnGroupDocChange : ReturnF
    , currentViewEntityListLazy : Lazy (List Entity)

    --msg
    , clearSelection : ReturnF
    , noop : ReturnF
    , openLaunchBarMsg : ReturnF
    , revertExclusiveMode : ReturnF
    , setDomFocusToFocusInEntityCmd : ReturnF
    , onSaveTodoForm : TodoForm -> ReturnF
    , onSaveGroupDocForm : GroupDocForm -> ReturnF
    , onSetExclusiveMode : ExclusiveMode -> ReturnF
    , onSaveExclusiveModeForm : ReturnF
    , onToggleContextArchived : DocId -> ReturnF
    , onToggleContextDeleted : DocId -> ReturnF
    , onToggleProjectArchived : DocId -> ReturnF
    , onToggleProjectDeleted : DocId -> ReturnF
    , switchToContextsView : ReturnF
    , setFocusInEntityWithEntityId : EntityId -> ReturnF
    , setFocusInEntity : Entity -> ReturnF
    , closeNotification : String -> ReturnF
    , onStartSetupAddTodo : ReturnF
    , onSwitchToNewUserSetupModeIfNeeded : ReturnF
    , onPersistLocalPref : ReturnF

    -- todo msg
    , afterTodoUpsert : TodoDoc -> ReturnF
    , onStartAddingTodoWithFocusInEntityAsReference : ReturnF
    , onStartAddingTodoToInbox : ReturnF
    , onToggleTodoArchived : DocId -> ReturnF
    , onToggleTodoDeleted : DocId -> ReturnF
    , switchToEntityListView : EntityListViewType -> ReturnF
    , onStartEditingTodo : TodoDoc -> ReturnF
    }


updateConfig : (AppMsg -> Return.ReturnF AppMsg AppModel) -> AppModel -> UpdateConfig
updateConfig andThenUpdate model =
    { --model
      now = model.now
    , activeProjects = (Model.GroupDocStore.getActiveProjects model)
    , activeContexts = (Model.GroupDocStore.getActiveContexts model)
    , updateEntityListCursorOnTodoChange = map (Model.EntityList.updateEntityListCursorOnTodoChange model)
    , updateEntityListCursorOnGroupDocChange =
        map (Model.EntityList.updateEntityListCursorOnGroupDocChange model)
    , currentViewEntityListLazy =
        Lazy.lazy
            (\_ ->
                Model.EntityList.createEntityListForCurrentView model
            )

    --msg
    , clearSelection = map Model.Selection.clearSelection
    , noop = andThenUpdate Msg.noop
    , openLaunchBarMsg = andThenUpdate Msg.openLaunchBarMsg
    , revertExclusiveMode = andThenUpdate Msg.revertExclusiveMode
    , setDomFocusToFocusInEntityCmd = andThenUpdate Msg.setDomFocusToFocusInEntityCmd
    , onSaveTodoForm = Msg.onSaveTodoForm >> andThenUpdate
    , onSaveGroupDocForm = Msg.onSaveGroupDocForm >> andThenUpdate
    , onSetExclusiveMode = Msg.onSetExclusiveMode >> andThenUpdate
    , onSaveExclusiveModeForm = Msg.onSaveExclusiveModeForm |> andThenUpdate
    , onToggleContextArchived = Msg.onToggleContextArchived >> andThenUpdate
    , onToggleContextDeleted = Msg.onToggleContextDeleted >> andThenUpdate
    , onToggleProjectArchived = Msg.onToggleProjectArchived >> andThenUpdate
    , onToggleProjectDeleted = Msg.onToggleProjectDeleted >> andThenUpdate
    , switchToContextsView = Msg.switchToContextsView |> andThenUpdate
    , setFocusInEntityWithEntityId =
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
    , onStartSetupAddTodo = andThenUpdate TodoMsg.onStartSetupAddTodo
    , onSwitchToNewUserSetupModeIfNeeded =
        andThenUpdate Msg.onSwitchToNewUserSetupModeIfNeeded
    , onPersistLocalPref = andThenUpdate Msg.onPersistLocalPref

    -- todo msg
    , afterTodoUpsert = TodoMsg.afterTodoUpsert >> andThenUpdate
    , onStartAddingTodoWithFocusInEntityAsReference =
        andThenUpdate TodoMsg.onStartAddingTodoWithFocusInEntityAsReference
    , onStartAddingTodoToInbox = andThenUpdate TodoMsg.onStartAddingTodoToInbox
    , onToggleTodoArchived = TodoMsg.onToggleDoneAndMaybeSelection >> andThenUpdate
    , onToggleTodoDeleted = TodoMsg.onToggleDeletedAndMaybeSelection >> andThenUpdate
    , switchToEntityListView = Msg.switchToEntityListView >> andThenUpdate
    , onStartEditingTodo = TodoMsg.onStartEditingTodo >> andThenUpdate
    }


update :
    (AppMsg -> Return.ReturnF AppMsg AppModel)
    -> AppMsg
    -> Return.ReturnF AppMsg AppModel
update andThenUpdate msg =
    returnWith (updateConfig andThenUpdate)
        (updateInner # msg)


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
