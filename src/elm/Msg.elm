module Msg exposing (..)

import AppDrawer.Types
import CommonMsg.Types
import Entity.Types exposing (EntityListViewType, EntityType)
import ExclusiveMode.Types exposing (ExclusiveMode, SyncForm)
import Firebase.Types exposing (FirebaseMsg)
import LaunchBar.Types exposing (LBMsg)
import Menu.Types exposing (MenuState)
import Time exposing (Time)
import Todo.FormTypes exposing (AddTodoForm, TodoAction, TodoEditForm, TodoGroupFrom)


--safe

import Todo.Msg
import Toolkit.Operators exposing (..)
import X.Function exposing (..)
import X.Function.Infix exposing (..)
import List.Extra as List
import Maybe.Extra as Maybe
import Json.Decode as D exposing (Decoder)
import Json.Decode.Pipeline as D
import Json.Encode as E
import Todo.Notification.Model
import Todo.Types exposing (TodoDoc, TodoText)


-- later

import Material
import X.Keyboard
import Keyboard.Combo


type ViewType
    = EntityListView EntityListViewType
    | SyncView


type SubMsg
    = OnNowChanged Time
    | OnKeyboardMsg X.Keyboard.Msg
    | OnGlobalKeyUp X.Keyboard.Key
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
    | OnNewTodoTextChanged AddTodoForm TodoText
    | OnDeactivateEditingMode
    | OnStartEditingReminder TodoDoc
    | OnStartEditingContext TodoDoc
    | OnStartEditingProject TodoDoc
    | OnSaveCurrentForm
    | OnUpdateRemoteSyncFormUri SyncForm String
    | OnEditTodoProjectMenuStateChanged TodoGroupFrom MenuState
    | OnEditTodoContextMenuStateChanged TodoGroupFrom MenuState
    | OnUpdateTodoForm TodoEditForm TodoAction
    | OnEntityListKeyDown (List EntityType) X.Keyboard.KeyboardEvent
    | OnSetViewType ViewType
    | OnEntityMsg EntityType Entity.Types.Msg
    | OnLaunchBarMsg LBMsg
    | OnLaunchBarMsgWithNow LBMsg Time
    | OnTodoMsg Todo.Msg.Msg
    | OnTodoMsgWithTime Todo.Msg.Msg Time
    | OnFirebaseMsg FirebaseMsg
    | OnKeyCombo Keyboard.Combo.Msg
    | OnCloseNotification String
    | OnAppDrawerMsg AppDrawer.Types.Msg
    | OnPersistLocalPref
    | OnMdl (Material.Msg Msg)
