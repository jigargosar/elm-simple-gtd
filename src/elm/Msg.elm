module Msg exposing (..)

import AppDrawer.Types
import CommonMsg.Types
import Entity.Types


--safe

import ExclusiveMode
import Firebase
import Keyboard.Combo
import Keyboard.Extra
import LaunchBar
import Material
import Time exposing (Time)
import Todo
import Todo.Form
import Todo.GroupForm
import Todo.Msg
import Todo.NewForm
import Toolkit.Helpers exposing (..)
import Toolkit.Operators exposing (..)
import X.Function exposing (..)
import X.Function.Infix exposing (..)
import List.Extra as List
import Maybe.Extra as Maybe
import X.Keyboard
import Json.Decode as D exposing (Decoder)
import Json.Decode.Pipeline as D
import Json.Encode as E
import Menu
import Todo.Notification.Model


type ViewType
    = EntityListView Entity.Types.ListViewType
    | SyncView


type SubMsg
    = OnNowChanged Time
    | OnKeyboardMsg X.Keyboard.Msg
    | OnGlobalKeyUp Keyboard.Extra.Key
    | OnPouchDBChange String D.Value
    | OnFirebaseDatabaseChange String D.Value


type Msg
    = OnCommonMsg CommonMsg.Types.Msg
    | OnSubMsg SubMsg
    | OnStartExclusiveMode ExclusiveMode.ExclusiveMode
    | OnShowMainMenu
    | OnMainMenuStateChanged Menu.State
    | OnRemotePouchSync ExclusiveMode.SyncForm
    | OnReminderOverlayAction Todo.Notification.Model.Action
    | OnNewTodoForInbox
    | OnNewProject
    | OnNewContext
    | OnNewTodoTextChanged Todo.NewForm.Model Todo.Text
    | OnDeactivateEditingMode
    | OnStartEditingReminder Todo.Model
    | OnStartEditingContext Todo.Model
    | OnStartEditingProject Todo.Model
    | OnSaveCurrentForm
    | OnUpdateRemoteSyncFormUri ExclusiveMode.SyncForm String
    | OnEditTodoProjectMenuStateChanged Todo.GroupForm.Model Menu.State
    | OnEditTodoContextMenuStateChanged Todo.GroupForm.Model Menu.State
    | OnUpdateTodoForm Todo.Form.Model Todo.Form.Action
    | OnEntityListKeyDown (List Entity.Types.Entity) X.Keyboard.KeyboardEvent
    | OnSetViewType ViewType
    | OnEntityMsg Entity.Types.Entity Entity.Types.Msg
    | OnLaunchBarMsg LaunchBar.Msg
    | OnLaunchBarMsgWithNow LaunchBar.Msg Time
    | OnTodoMsg Todo.Msg.Msg
    | OnTodoMsgWithTime Todo.Msg.Msg Time
    | OnFirebaseMsg Firebase.Msg
    | OnKeyCombo Keyboard.Combo.Msg
    | OnCloseNotification String
    | OnAppDrawerMsg AppDrawer.Types.Msg
    | OnPersistLocalPref
    | OnMdl (Material.Msg Msg)
