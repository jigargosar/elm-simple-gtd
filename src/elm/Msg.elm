module Msg exposing (..)

import AppDrawer.Types
import CommonMsg.Types
import Entity.Types exposing (EntityType)
import ExclusiveMode.Types exposing (ExclusiveMode, SyncForm)
import Firebase.Types exposing (FirebaseMsg)
import LaunchBar.Types exposing (LBMsg)
import Menu.Types exposing (MenuState)
import Time exposing (Time)
import Todo.FormTypes exposing (AddTodoForm, EditTodoFormAction, TodoEditForm, TodoGroupFrom)
import Todo.Types exposing (TodoDoc, TodoText)
import Json.Encode as E


--safe

import Todo.Msg exposing (TodoMsg)
import Todo.Notification.Model
import Material
import X.Keyboard
import Keyboard.Combo
import ViewType exposing (ViewType)


type SubMsg
    = OnNowChanged Time
    | OnKeyboardMsg X.Keyboard.Msg
    | OnGlobalKeyUp X.Keyboard.Key
    | OnPouchDBChange String E.Value
    | OnFirebaseDatabaseChange String E.Value


type Msg
    = OnCommonMsg CommonMsg.Types.Msg
    | OnSubMsg SubMsg
    | OnStartExclusiveMode ExclusiveMode
    | OnShowMainMenu
    | OnMainMenuStateChanged MenuState
    | OnRemotePouchSync SyncForm
    | OnReminderOverlayAction Todo.Notification.Model.Action
    | OnNewTodoForInbox
    | OnNewProject
    | OnNewContext
    | OnNewTodoTextChanged AddTodoForm TodoText
    | OnDeactivateEditingMode
    | OnStartEditingReminder TodoDoc
    | OnStartEditingContext TodoDoc
    | OnStartEditingProject TodoDoc
    | OnSaveCurrentForm
    | OnUpdateRemoteSyncFormUri SyncForm String
    | OnEditTodoProjectMenuStateChanged TodoGroupFrom MenuState
    | OnEditTodoContextMenuStateChanged TodoGroupFrom MenuState
    | OnUpdateTodoForm TodoEditForm EditTodoFormAction
    | OnEntityListKeyDown (List EntityType) X.Keyboard.KeyboardEvent
    | OnSetViewType ViewType
    | OnEntityMsg EntityType Entity.Types.Msg
    | OnLaunchBarMsg LBMsg
    | OnLaunchBarMsgWithNow LBMsg Time
    | OnTodoMsg TodoMsg
    | OnTodoMsgWithTime TodoMsg Time
    | OnFirebaseMsg FirebaseMsg
    | OnKeyCombo Keyboard.Combo.Msg
    | OnCloseNotification String
    | OnAppDrawerMsg AppDrawer.Types.Msg
    | OnPersistLocalPref
    | OnMdl (Material.Msg Msg)
