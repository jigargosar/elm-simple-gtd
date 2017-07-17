module Msg exposing (..)

import AppDrawer.Types
import CommonMsg.Types
import Entity.Types exposing (EntityListViewType(..))
import ExclusiveMode.Types exposing (..)
import Firebase.Types exposing (FirebaseMsg)
import LaunchBar.Messages
import Menu.Types exposing (MenuState)
import Msg.AppHeader exposing (AppHeaderMsg(..))
import Msg.ViewType exposing (ViewTypeMsg(..))
import Time exposing (Time)
import Json.Encode as E
import X.Function.Infix exposing (..)
import Todo.Msg exposing (TodoMsg)
import Material
import X.Keyboard
import Keyboard.Combo
import Msg.CustomSync exposing (CustomSyncMsg(..))
import Msg.ExclusiveMode exposing (ExclusiveModeMsg)


type SubscriptionMsg
    = OnNowChanged Time
    | OnKeyboardMsg X.Keyboard.Msg
    | OnGlobalKeyUp X.Keyboard.Key
    | OnPouchDBChange String E.Value
    | OnFirebaseDatabaseChange String E.Value
    | OnKeyCombo Keyboard.Combo.Msg


type AppMsg
    = OnCommonMsg CommonMsg.Types.Msg
    | OnSubscriptionMsg SubscriptionMsg
    | OnViewTypeMsg ViewTypeMsg
    | OnExclusiveModeMsg ExclusiveModeMsg
    | OnAppHeaderMsg AppHeaderMsg
    | OnCustomSyncMsg CustomSyncMsg
    | OnEntityMsg Entity.Types.EntityMsg
    | LaunchBarMsg LaunchBar.Messages.LaunchBarMsg
    | LaunchBarMsgWithNow LaunchBar.Messages.LaunchBarMsg Time
    | OnTodoMsg TodoMsg
    | OnTodoMsgWithNow TodoMsg Time
    | OnFirebaseMsg FirebaseMsg
    | OnCloseNotification String
    | OnAppDrawerMsg AppDrawer.Types.Msg
    | OnPersistLocalPref
    | OnMdl (Material.Msg AppMsg)


switchToEntityListView =
    SwitchToEntityListView >> OnViewTypeMsg


switchToView =
    SwitchView >> OnViewTypeMsg


foo =
    16


onNewProject =
    Entity.Types.EM_StartAddingProject |> OnEntityMsg


onNewContext =
    Entity.Types.EM_StartAddingContext |> OnEntityMsg


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


openLaunchBarMsg =
    LaunchBar.Messages.Open |> LaunchBarMsg
