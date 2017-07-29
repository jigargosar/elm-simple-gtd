module Msg exposing (..)

import AppDrawer.Types
import CommonMsg
import CommonMsg.Types
import Entity.Types exposing (..)
import LaunchBar.Messages exposing (LaunchBarMsg)
import Material
import Msg.AppHeader exposing (AppHeaderMsg(..))
import Msg.CustomSync exposing (CustomSyncMsg(..))
import Msg.ExclusiveMode exposing (ExclusiveModeMsg)
import Msg.Firebase exposing (..)
import Msg.GroupDoc exposing (GroupDocMsg)
import Msg.Subscription exposing (SubscriptionMsg)
import Page exposing (PageMsg(..))
import Time exposing (Time)
import Todo.Msg exposing (TodoMsg)
import Toolkit.Operators exposing (..)
import Types.Firebase exposing (..)
import Types.GroupDoc exposing (..)
import X.Function.Infix exposing (..)


type AppMsg
    = OnCommonMsg CommonMsg.Types.Msg
    | OnSubscriptionMsg SubscriptionMsg
    | OnPageMsg PageMsg
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


switchToEntityListPageMsg =
    SwitchToEntityListView >> OnPageMsg


gotoPageMsg =
    SwitchView >> OnPageMsg



-- fb


onSwitchToNewUserSetupModeIfNeeded =
    OnFirebaseMsg OnFB_SwitchToNewUserSetupModeIfNeeded


onSignIn =
    OnFirebaseMsg OnFBSignIn


onSignOut =
    OnFirebaseMsg OnFBSignOut



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


updateEntityListCursorMsg =
    EM_UpdateEntityListCursor |> OnEntityMsg


onEntityUpdateMsg =
    Entity.Types.EM_Update >>> OnEntityMsg


entityListFocusPreviousEntityMsg =
    Entity.Types.EM_EntityListFocusPrev |> OnEntityMsg


entityListFocusNextEntityMsg =
    Entity.Types.EM_EntityListFocusNext |> OnEntityMsg


onToggleEntitySelection =
    EM_Update # EUA_ToggleSelection >> OnEntityMsg


bringEntityIdInViewMsg =
    EM_Update # EUA_BringEntityIdInView >> OnEntityMsg


setFocusInEntityWithEntityIdMsg =
    EM_SetFocusInEntityWithEntityId >> OnEntityMsg



-- tdo


onSaveTodoForm =
    Todo.Msg.OnSaveTodoForm >> OnTodoMsg



-- gd


onSaveGroupDocForm =
    Msg.GroupDoc.OnSaveGroupDocForm >> OnGroupDocMsg


onToggleGroupDocArchived groupDocId =
    Msg.GroupDoc.OnGroupDocIdAction groupDocId GDA_ToggleArchived |> OnGroupDocMsg


onStartEditingGroupDoc groupDocId =
    Msg.GroupDoc.OnGroupDocIdAction groupDocId GDA_StartEditing |> OnGroupDocMsg


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
