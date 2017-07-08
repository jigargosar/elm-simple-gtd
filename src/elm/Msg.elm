module Msg exposing (..)

import AppDrawer.Types
import CommonMsg.Types
import Entity.Types


--safe

import ExclusiveMode.Types exposing (ExclusiveMode, SyncForm)
import Firebase
import Keyboard.Combo
import Keyboard.Extra
import LaunchBar
import Material
import Menu.Types exposing (MenuState)
import Time exposing (Time)
import Todo
import Todo.Form
import Todo.FormTypes exposing (TodoEditForm, TodoGroupFrom)
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
import Todo.Types exposing (TodoDoc)


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
    | OnStartExclusiveMode ExclusiveMode
    | OnShowMainMenu
    | OnMainMenuStateChanged MenuState
    | OnRemotePouchSync SyncForm
    | OnReminderOverlayAction Todo.Notification.Model.Action
    | OnNewTodoForInbox
    | OnNewProject
    | OnNewContext
    | OnNewTodoTextChanged Todo.NewForm.Model Todo.Text
    | OnDeactivateEditingMode
    | OnStartEditingReminder TodoDoc
    | OnStartEditingContext TodoDoc
    | OnStartEditingProject TodoDoc
    | OnSaveCurrentForm
    | OnUpdateRemoteSyncFormUri SyncForm String
    | OnEditTodoProjectMenuStateChanged TodoGroupFrom MenuState
    | OnEditTodoContextMenuStateChanged TodoGroupFrom MenuState
    | OnUpdateTodoForm TodoEditForm Todo.Form.Action
    | OnEntityListKeyDown (List Entity.Types.EntityType) X.Keyboard.KeyboardEvent
    | OnSetViewType ViewType
    | OnEntityMsg Entity.Types.EntityType Entity.Types.Msg
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
