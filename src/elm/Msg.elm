module Msg exposing (..)

import AppDrawer.Types
import CommonMsg.Types
import Entity.Types exposing (Entity, EntityMsg)
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


type SubscriptionMsg
    = OnNowChanged Time
    | OnKeyboardMsg X.Keyboard.Msg
    | OnGlobalKeyUp X.Keyboard.Key
    | OnPouchDBChange String E.Value
    | OnFirebaseDatabaseChange String E.Value
    | OnKeyCombo Keyboard.Combo.Msg


type ExclusiveModeMsg
    = OnSetExclusiveMode ExclusiveMode
    | OnSetExclusiveModeToNoneAndTryRevertingFocus
    | OnSaveExclusiveModeForm


type AppHeaderMsg
    = OnShowMainMenu
    | OnMainMenuStateChanged MenuState


type CustomSyncMsg
    = OnStartCustomSync SyncForm
    | OnUpdateCustomSyncFormUri SyncForm String


type AppMsg
    = OnCommonMsg CommonMsg.Types.Msg
    | OnSubscriptionMsg SubscriptionMsg
    | OnExclusiveModeMsg ExclusiveModeMsg
    | OnAppHeaderMsg AppHeaderMsg
    | OnCustomSyncMsg CustomSyncMsg
    | OnSetViewType ViewType
    | OnEntityMsg EntityMsg
    | LaunchBarMsg LaunchBar.Messages.Msg
    | LaunchBarMsgWithNow LaunchBar.Messages.Msg Time
    | OnTodoMsg TodoMsg
    | OnTodoMsgWithNow TodoMsg Time
    | OnFirebaseMsg FirebaseMsg
    | OnCloseNotification String
    | OnAppDrawerMsg AppDrawer.Types.Msg
    | OnPersistLocalPref
    | OnMdl (Material.Msg AppMsg)


onSetEntityListView =
    EntityListView >> OnSetViewType


onNewProject =
    OnEntityMsg Entity.Types.EM_StartAddingProject


onNewContext =
    OnEntityMsg Entity.Types.EM_StartAddingContext


onEntityUpdateMsg =
    Entity.Types.EM_Update >>> OnEntityMsg


onEntityListKeyDown =
    Entity.Types.EM_EntityListKeyDown >>> OnEntityMsg


onSwitchToNewUserSetupModeIfNeeded =
    OnFirebaseMsg Firebase.Types.OnFB_SwitchToNewUserSetupModeIfNeeded


onShowMainMenu =
    OnShowMainMenu |> OnAppHeaderMsg


onMainMenuStateChanged =
    OnMainMenuStateChanged >> OnAppHeaderMsg


onStartCustomRemotePouchSync =
    OnStartCustomSync >> OnCustomSyncMsg


onUpdateCustomSyncFormUri =
    OnUpdateCustomSyncFormUri >>> OnCustomSyncMsg
