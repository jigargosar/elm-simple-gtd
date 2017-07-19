module View exposing (init)

import AppDrawer.Model
import AppDrawer.Types
import AppDrawer.View
import Entity.View
import Model.ViewType
import Msg
import TodoMsg
import View.CustomSync
import View.Layout
import X.Html exposing (boolProperty, onClickStopPropagation)
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import View.Header
import ViewModel
import View.Mat
import Types.ViewType exposing (ViewType(EntityListView, SyncView))
import View.Overlays


config =
    { onSetProject = TodoMsg.onSetProjectAndMaybeSelection
    , onSetContext = TodoMsg.onSetContextAndMaybeSelection
    , onSetTodoFormMenuState = TodoMsg.onSetTodoFormMenuState
    , noop = Msg.noop
    , revertExclusiveMode = Msg.revertExclusiveMode
    , onSetTodoFormText = TodoMsg.onSetTodoFormText
    , onToggleDeleted = TodoMsg.onToggleDeleted
    , onSetTodoFormReminderDate = TodoMsg.onSetTodoFormReminderDate
    , onSetTodoFormReminderTime = TodoMsg.onSetTodoFormReminderTime
    , onSaveExclusiveModeForm = Msg.onSaveExclusiveModeForm
    , onEntityUpdateMsg = Msg.onEntityUpdateMsg
    , onMainMenuStateChanged = Msg.onMainMenuStateChanged
    , onSignIn = Msg.onSignIn
    , onSignOut = Msg.onSignOut
    , onLaunchBarMsg = Msg.OnLaunchBarMsg
    , onFirebaseMsg = Msg.OnFirebaseMsg
    , onReminderOverlayAction = TodoMsg.onReminderOverlayAction
    , onToggleAppDrawerOverlay = Msg.onToggleAppDrawerOverlay
    }


init model =
    let
        alv =
            View.Layout.appLayoutView config model

        children =
            [ alv
            , View.Mat.newTodoFab alv model
            ]
                ++ View.Overlays.overlayViews config model
    in
        div [ class "mdl-typography--body-1" ] children
