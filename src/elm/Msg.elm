module Msg exposing (..)

import AppDrawer.Types
import CommonMsg.Types
import Entity.Types exposing (..)
import ExclusiveMode.Types exposing (..)
import Firebase.Types exposing (FirebaseMsg)
import LaunchBar.Messages exposing (LaunchBarMsg)
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
import Toolkit.Operators exposing (..)
import Toolkit.Helpers exposing (..)


type SubscriptionMsg
    = OnNowChanged Time
    | OnKeyboardMsg X.Keyboard.Msg
    | OnGlobalKeyUp X.Keyboard.Key
    | OnPouchDBChange String E.Value
    | OnFirebaseDatabaseChange String E.Value


type AppMsg
    = OnCommonMsg CommonMsg.Types.Msg
    | OnSubscriptionMsg SubscriptionMsg
    | OnViewTypeMsg ViewTypeMsg
    | OnExclusiveModeMsg ExclusiveModeMsg
    | OnAppHeaderMsg AppHeaderMsg
    | OnCustomSyncMsg CustomSyncMsg
    | OnEntityMsg Entity.Types.EntityMsg
    | OnLaunchBarMsg LaunchBarMsg
    | OnLaunchBarMsgWithNow LaunchBarMsg Time
    | OnTodoMsg TodoMsg
    | OnTodoMsgWithNow TodoMsg Time
    | OnFirebaseMsg FirebaseMsg
    | OnCloseNotification String
    | OnAppDrawerMsg AppDrawer.Types.Msg
    | OnPersistLocalPref
    | OnMdl (Material.Msg AppMsg)



--  view type


switchToEntityListView =
    SwitchToEntityListView >> OnViewTypeMsg


switchToView =
    SwitchView >> OnViewTypeMsg


switchToContextsViewMsg =
    SwitchToContextsView |> OnViewTypeMsg



-- fb


onSwitchToNewUserSetupModeIfNeeded =
    OnFirebaseMsg Firebase.Types.OnFB_SwitchToNewUserSetupModeIfNeeded



-- mm


onShowMainMenu =
    OnShowMainMenu |> OnAppHeaderMsg


onMainMenuStateChanged =
    OnMainMenuStateChanged >> OnAppHeaderMsg



--cs


onStartCustomRemotePouchSync =
    OnStartCustomSync >> OnCustomSyncMsg


onUpdateCustomSyncFormUri =
    OnUpdateCustomSyncFormUri >>> OnCustomSyncMsg



-- lbm


openLaunchBarMsg =
    LaunchBar.Messages.Open |> OnLaunchBarMsg



-- ex mode


revertExclusiveMode =
    Msg.ExclusiveMode.OnSetExclusiveModeToNoneAndTryRevertingFocus |> OnExclusiveModeMsg


onSetExclusiveMode =
    Msg.ExclusiveMode.OnSetExclusiveMode >> OnExclusiveModeMsg


onSaveExclusiveModeForm =
    Msg.ExclusiveMode.OnSaveExclusiveModeForm |> OnExclusiveModeMsg



-- entityMsg


onNewProject =
    Entity.Types.EM_StartAddingProject |> OnEntityMsg


onNewContext =
    Entity.Types.EM_StartAddingContext |> OnEntityMsg


onEntityUpdateMsg =
    Entity.Types.EM_Update >>> OnEntityMsg


onEntityListKeyDown =
    Entity.Types.EM_EntityListKeyDown >>> OnEntityMsg


onToggleEntitySelection =
    EM_Update # EUA_ToggleSelection >> OnEntityMsg


onStartEditingEntity =
    EM_Update # EUA_StartEditing >> OnEntityMsg



--
