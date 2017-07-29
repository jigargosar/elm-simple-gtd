module View.Config exposing (..)

import AppDrawer.Types
import Document
import Entity.Types exposing (..)
import ExclusiveMode.Types
import Firebase.Types
import GroupDoc.Types
import LaunchBar.Messages
import Material
import Menu
import Menu.Types
import Msg
import Msg.GroupDoc
import Page
import Pages.EntityList exposing (..)
import Todo.FormTypes
import Todo.Msg
import Todo.Notification.Model
import Todo.Types
import Types.Document exposing (..)
import X.Function.Infix exposing (..)


type alias ViewConfig msg =
    { noop : msg
    , onEntityUpdateMsg : EntityId -> EntityUpdateAction -> msg
    , onAppDrawerMsg : AppDrawer.Types.Msg -> msg
    , onFirebaseMsg : Firebase.Types.FirebaseMsg -> msg
    , onLaunchBarMsg : LaunchBar.Messages.LaunchBarMsg -> msg
    , onMainMenuStateChanged : Menu.Types.MenuState -> msg
    , onMdl : Material.Msg msg -> msg
    , onReminderOverlayAction : Todo.Notification.Model.Action -> msg
    , onSaveExclusiveModeForm : msg
    , onSetContext : DocId -> GroupDoc.Types.ContextDoc -> msg
    , onSetProject : DocId -> GroupDoc.Types.ProjectDoc -> msg
    , onSetTodoFormMenuState : Todo.FormTypes.TodoForm -> Menu.State -> msg
    , onSetTodoFormReminderDate : Todo.FormTypes.TodoForm -> String -> msg
    , onSetTodoFormReminderTime : Todo.FormTypes.TodoForm -> String -> msg
    , onSetTodoFormText : Todo.FormTypes.TodoForm -> String -> msg
    , onShowMainMenu : msg
    , onSignIn : msg
    , onSignOut : msg
    , onStartAddingGroupDoc : GroupDoc.Types.GroupDocType -> msg
    , onStartAddingTodoWithFocusInEntityAsReference : msg
    , onStartCustomRemotePouchSync : ExclusiveMode.Types.SyncForm -> msg
    , onStartEditingGroupDoc : GroupDoc.Types.GroupDocId -> msg
    , onStartEditingReminder : Todo.Types.TodoDoc -> msg
    , onStartEditingTodoContext : Todo.Types.TodoDoc -> msg
    , onStartEditingTodoProject : Todo.Types.TodoDoc -> msg
    , onStartEditingTodoText : Todo.Types.TodoDoc -> msg
    , onStopRunningTodoMsg : msg
    , onSwitchOrStartTrackingTodo : DocId -> msg
    , onToggleAppDrawerOverlay : msg
    , onToggleDeleted : DocId -> msg
    , onToggleDeletedAndMaybeSelection : DocId -> msg
    , onToggleDoneAndMaybeSelection : DocId -> msg
    , onToggleEntitySelection : Entity.Types.EntityId -> msg
    , onToggleGroupDocArchived : GroupDoc.Types.GroupDocId -> msg
    , onUpdateCustomSyncFormUri :
        ExclusiveMode.Types.SyncForm -> String -> msg
    , revertExclusiveMode : msg
    , setFocusInEntityWithEntityId : Entity.Types.EntityId -> msg
    , updateGroupDocFromNameMsg :
        GroupDoc.Types.GroupDocForm -> GroupDoc.Types.GroupDocName -> msg
    , switchToEntityListPageMsg : EntityListPageModel -> msg
    , gotoPageMsg : Page.Page -> msg
    }


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
    , switchToEntityListPageMsg = Msg.switchToEntityListPageMsg
    , gotoPageMsg = Msg.gotoPageMsg
    , onMdl = Msg.onMdl
    , onShowMainMenu = Msg.onShowMainMenu
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
