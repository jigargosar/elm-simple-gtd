module Msg exposing (..)

import AppDrawer.Types
import CommonMsg.Types
import Entity.Types exposing (Entity)
import ExclusiveMode.Types exposing (..)
import Firebase.Types exposing (FirebaseMsg)
import LaunchBar.Messages
import Menu.Types exposing (MenuState)
import Time exposing (Time)
import Todo.FormTypes exposing (AddTodoForm, EditTodoForm, EditTodoFormAction, XMEditTodoType)
import Todo.Types exposing (TodoDoc, TodoText)
import Json.Encode as E
import X.Function.Infix exposing (..)


----safe

import Todo.Msg exposing (TodoMsg)
import Material
import X.Keyboard
import Keyboard.Combo
import ViewType exposing (ViewType(EntityListView))


type SubMsg
    = OnNowChanged Time
    | OnKeyboardMsg X.Keyboard.Msg
    | OnGlobalKeyUp X.Keyboard.Key
    | OnPouchDBChange String E.Value
    | OnFirebaseDatabaseChange String E.Value


type MainMsg
    = OnSwitchToNewUserSetupModeIfNeeded


type Msg
    = OnCommonMsg CommonMsg.Types.Msg
    | OnSubMsg SubMsg
    | OnStartExclusiveMode ExclusiveMode
    | OnStartEditingTodo TodoDoc XMEditTodoType
    | OnMainMsg MainMsg
    | OnShowMainMenu
    | OnMainMenuStateChanged MenuState
    | OnRemotePouchSync SyncForm
    | OnNewTodoTextChanged AddTodoForm TodoText
    | OnDeactivateEditingMode
    | OnStartEditingReminder TodoDoc
    | OnStartEditingTodoContext TodoDoc
    | OnStartEditingTodoProject TodoDoc
    | OnSaveCurrentForm
    | OnUpdateRemoteSyncFormUri SyncForm String
    | OnUpdateTodoForm EditTodoForm EditTodoFormAction
    | OnEntityListKeyDown (List Entity) X.Keyboard.KeyboardEvent
    | OnSetViewType ViewType
    | OnEntityMsg Entity.Types.EntityMsg
    | LaunchBarMsg LaunchBar.Messages.Msg
    | LaunchBarMsgWithNow LaunchBar.Messages.Msg Time
    | OnTodoMsg TodoMsg
    | OnTodoMsgWithTime TodoMsg Time
    | OnFirebaseMsg FirebaseMsg
    | OnKeyCombo Keyboard.Combo.Msg
    | OnCloseNotification String
    | OnAppDrawerMsg AppDrawer.Types.Msg
    | OnPersistLocalPref
    | OnMdl (Material.Msg Msg)


onSetEntityListView =
    EntityListView >> OnSetViewType


onNewProject =
    OnEntityMsg Entity.Types.OnNewProject


onNewContext =
    OnEntityMsg Entity.Types.OnNewContext


onEntityUpdateMsg =
    Entity.Types.OnUpdate >>> OnEntityMsg


onSwitchToNewUserSetupModeIfNeeded =
    OnMainMsg OnSwitchToNewUserSetupModeIfNeeded
