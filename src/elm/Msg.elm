module Msg exposing (..)

import AppDrawer.Types
import CommonMsg
import CommonMsg.Types
import Entity.Types exposing (..)
import Firebase.Types exposing (FirebaseMsg)
import GroupDoc.Types exposing (GroupDocAction(..), GroupDocIdAction(..))
import LaunchBar.Messages exposing (LaunchBarMsg)
import Material
import Msg.AppHeader exposing (AppHeaderMsg(..))
import Msg.CustomSync exposing (CustomSyncMsg(..))
import Msg.ExclusiveMode exposing (ExclusiveModeMsg)
import Msg.GroupDoc exposing (GroupDocMsg)
import Msg.Subscription exposing (SubscriptionMsg)
import Msg.ViewType exposing (ViewTypeMsg(..))
import Time exposing (Time)
import Todo.Msg exposing (TodoMsg)
import Toolkit.Operators exposing (..)
import X.Function.Infix exposing (..)


type AppMsg
    = OnCommonMsg CommonMsg.Types.Msg
    | OnSubscriptionMsg SubscriptionMsg
    | OnViewTypeMsg ViewTypeMsg
    | OnExclusiveModeMsg ExclusiveModeMsg
    | OnAppHeaderMsg AppHeaderMsg
    | OnCustomSyncMsg CustomSyncMsg
    | OnEntityMsg Entity.Types.EntityMsg
    | SetFocusInEntity Entity
    | SetFocusInEntityWithEntityId EntityId
    | OnLaunchBarMsg LaunchBarMsg
    | OnLaunchBarMsgWithNow LaunchBarMsg Time
    | OnGroupDocMsg GroupDocMsg
    | OnTodoMsg TodoMsg
    | OnTodoMsgWithNow TodoMsg Time
    | OnFirebaseMsg FirebaseMsg
    | OnAppDrawerMsg AppDrawer.Types.Msg
    | OnMdl (Material.Msg AppMsg)



-- common


commonMsg =
    CommonMsg.createHelper OnCommonMsg


noop =
    commonMsg.noOp


logString =
    commonMsg.logString


setDomFocusToFocusInEntityCmd =
    commonMsg.focus ".entity-list .focusable-list-item[tabindex=0]"



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


onToggleGroupDocArchived groupDocId =
    Msg.GroupDoc.OnGroupDocIdAction groupDocId GDA_ToggleArchived |> OnGroupDocMsg


onGD_UpdateFormName form newName =
    Msg.GroupDoc.OnGroupDocIdAction form.groupDocId
        (GDA_UpdateFormName form newName)
        |> OnGroupDocMsg


onStartEditingGroupDoc groupDocId =
    Msg.GroupDoc.OnGroupDocIdAction groupDocId GDA_StartEditing


onStartAddingGroupDoc gdType =
    Msg.GroupDoc.OnGroupDocAction gdType GDA_StartAdding |> OnGroupDocMsg



--drawer


onToggleAppDrawerOverlay =
    OnAppDrawerMsg AppDrawer.Types.OnToggleOverlay


onAppDrawerMsg =
    OnAppDrawerMsg



-- mdl


onMdl =
    OnMdl
