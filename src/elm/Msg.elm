module Msg exposing (..)

import AppDrawer.Types
import CommonMsg.Types
import Entity.Types exposing (Entity)
import ExclusiveMode.Types exposing (..)
import Firebase.Types exposing (FirebaseMsg)
import LaunchBar.Messages
import Menu.Types exposing (MenuState)
import Time exposing (Time)
import Todo.FormTypes exposing (..)
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


type AppMsg
    = OnCommonMsg CommonMsg.Types.Msg
    | OnSubMsg SubMsg
    | OnStartAddingTodo AddTodoFormMode
    | OnStartEditingTodo TodoDoc EditTodoFormMode
    | OnMainMsg MainMsg
    | OnShowMainMenu
    | OnMainMenuStateChanged MenuState
    | OnRemotePouchSync SyncForm
    | OnUpdateAddTodoForm AddTodoForm TodoText
    | OnDeactivateEditingMode
    | OnSaveCurrentForm
    | OnUpdateRemoteSyncFormUri SyncForm String
    | OnUpdateEditTodoForm EditTodoForm EditTodoFormAction
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
    | OnMdl (Material.Msg AppMsg)


onSetEntityListView =
    EntityListView >> OnSetViewType


onNewProject =
    OnEntityMsg Entity.Types.OnNewProject


onNewContext =
    OnEntityMsg Entity.Types.OnNewContext


onEntityUpdateMsg =
    Entity.Types.OnEntityUpdate >>> OnEntityMsg


onSwitchToNewUserSetupModeIfNeeded =
    OnMainMsg OnSwitchToNewUserSetupModeIfNeeded
