module Msg exposing (..)

import AppDrawer.Types
import CommonMsg
import CommonMsg.Types
import Entity.Types exposing (..)
import Firebase.Types exposing (FirebaseMsg)
import LaunchBar.Messages exposing (LaunchBarMsg)
import Msg.AppHeader exposing (AppHeaderMsg(..))
import Msg.GroupDoc exposing (GroupDocMsg)
import Msg.Subscription exposing (SubscriptionMsg)
import Msg.ViewType exposing (ViewTypeMsg(..))
import Time exposing (Time)
import X.Function.Infix exposing (..)
import Todo.Msg exposing (TodoMsg)
import Material
import Msg.CustomSync exposing (CustomSyncMsg(..))
import Msg.ExclusiveMode exposing (ExclusiveModeMsg)
import Toolkit.Operators exposing (..)


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
    | OnGroupDocMsg GroupDocMsg
    | OnTodoMsg TodoMsg
    | OnTodoMsgWithNow TodoMsg Time
    | OnFirebaseMsg FirebaseMsg
    | OnCloseNotification String
    | OnAppDrawerMsg AppDrawer.Types.Msg
    | OnPersistLocalPref
    | OnMdl (Material.Msg AppMsg)



-- common


commonMsg =
    CommonMsg.createHelper OnCommonMsg


noop =
    commonMsg.noOp


logString =
    let
        _ =
            2
    in
        commonMsg.logString


setDomFocusToFocusInEntityCmd =
    (commonMsg.focus ".entity-list .focusable-list-item[tabindex=0]")



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


onSignIn =
    OnFirebaseMsg Firebase.Types.OnFBSignIn


onSignOut =
    OnFirebaseMsg Firebase.Types.OnFBSignOut



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



-- tdo


onSaveTodoForm =
    Todo.Msg.OnSaveTodoForm >> OnTodoMsg



-- gd


onSaveGroupDocForm =
    Msg.GroupDoc.OnSaveGroupDocForm >> OnGroupDocMsg


onToggleContextArchived =
    Msg.GroupDoc.OnToggleContextArchived >> OnGroupDocMsg


onToggleProjectArchived =
    Msg.GroupDoc.OnToggleProjectArchived >> OnGroupDocMsg


onToggleContextDeleted =
    Msg.GroupDoc.OnToggleContextDeleted >> OnGroupDocMsg


onToggleProjectDeleted =
    Msg.GroupDoc.OnToggleProjectDeleted >> OnGroupDocMsg
