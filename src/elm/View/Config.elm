module View.Config exposing (..)

import AppDrawer.Types
import Document
import Entity.Types
import ExclusiveMode.Types
import Firebase.Types
import GroupDoc.Types
import LaunchBar.Messages
import Material
import Menu
import Menu.Types
import Msg
import Msg.GroupDoc
import Todo.FormTypes
import Todo.Msg
import Todo.Notification.Model
import Todo.Types
import View.Types exposing (ViewConfig)
import ViewType
import X.Function.Infix exposing (..)
import X.Keyboard


viewConfig : ViewConfig Msg.AppMsg
viewConfig =
    { onSetProject = Todo.Msg.onSetProjectAndMaybeSelection >>> Msg.OnTodoMsg
    , onSetContext = Todo.Msg.onSetContextAndMaybeSelection >>> Msg.OnTodoMsg
    , onSetTodoFormMenuState = Todo.Msg.onSetTodoFormMenuState >>> Msg.OnTodoMsg
    , noop = Msg.noop
    , revertExclusiveMode = Msg.revertExclusiveMode
    , onSetTodoFormText = Todo.Msg.onSetTodoFormText >>> Msg.OnTodoMsg
    , onToggleDeleted = Todo.Msg.onToggleDeleted >> Msg.OnTodoMsg
    , onSetTodoFormReminderDate = Todo.Msg.onSetTodoFormReminderDate >>> Msg.OnTodoMsg
    , onSetTodoFormReminderTime = Todo.Msg.onSetTodoFormReminderTime >>> Msg.OnTodoMsg
    , onSaveExclusiveModeForm = Msg.onSaveExclusiveModeForm
    , onEntityUpdateMsg = Msg.onEntityUpdateMsg
    , onMainMenuStateChanged = Msg.onMainMenuStateChanged
    , onSignIn = Msg.onSignIn
    , onSignOut = Msg.onSignOut
    , onLaunchBarMsg = Msg.OnLaunchBarMsg
    , onFirebaseMsg = Msg.OnFirebaseMsg
    , onReminderOverlayAction = Todo.Msg.onReminderOverlayAction >> Msg.OnTodoMsg
    , onToggleAppDrawerOverlay = Msg.onToggleAppDrawerOverlay
    , onAppDrawerMsg = Msg.onAppDrawerMsg
    , onStartAddingGroupDoc = Msg.onStartAddingGroupDoc
    , onUpdateCustomSyncFormUri = Msg.onUpdateCustomSyncFormUri
    , onStartCustomRemotePouchSync = Msg.onStartCustomRemotePouchSync
    , switchToEntityListViewTypeMsg = Msg.switchToEntityListViewTypeMsg
    , switchToView = Msg.switchToView
    , onMdl = Msg.onMdl
    , onShowMainMenu = Msg.onShowMainMenu
    , onEntityListKeyDown = Msg.onEntityListKeyDown
    , onStopRunningTodoMsg = Todo.Msg.onStopRunningTodoMsg |> Msg.OnTodoMsg
    , onStartAddingTodoWithFocusInEntityAsReference =
        Todo.Msg.onStartAddingTodoWithFocusInEntityAsReference |> Msg.OnTodoMsg
    , onToggleEntitySelection = Msg.onToggleEntitySelection
    , onStartEditingTodoProject = Todo.Msg.onStartEditingTodoProject >> Msg.OnTodoMsg
    , onStartEditingTodoContext = Todo.Msg.onStartEditingTodoContext >> Msg.OnTodoMsg
    , onSwitchOrStartTrackingTodo = Todo.Msg.onSwitchOrStartTrackingTodo >> Msg.OnTodoMsg
    , onStartEditingTodoText = Todo.Msg.onStartEditingTodoText >> Msg.OnTodoMsg
    , onStartEditingReminder = Todo.Msg.onStartEditingReminder >> Msg.OnTodoMsg
    , onToggleDeletedAndMaybeSelection = Todo.Msg.onToggleDeletedAndMaybeSelection >> Msg.OnTodoMsg
    , onToggleDoneAndMaybeSelection = Todo.Msg.onToggleDoneAndMaybeSelection >> Msg.OnTodoMsg
    , onToggleGroupDocArchived = Msg.onToggleGroupDocArchived
    , updateGroupDocFromNameMsg =
        Msg.GroupDoc.updateGroupDocFromNameMsg >>> Msg.OnGroupDocMsg
    , onStartEditingGroupDoc = Msg.onStartEditingGroupDoc
    , setFocusInEntityWithEntityId = Msg.setFocusInEntityWithEntityIdMsg
    }
