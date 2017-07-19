module View exposing (init)

import Msg
import TodoMsg
import View.Layout
import Html exposing (..)
import Html.Attributes exposing (..)
import ViewModel
import View.Mat
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
    , onUpdateCustomSyncFormUri = Msg.onUpdateCustomSyncFormUri
    , onStartCustomRemotePouchSync = Msg.onStartCustomRemotePouchSync
    , switchToEntityListView = Msg.switchToEntityListView
    , switchToView = Msg.switchToView
    , onMdl = Msg.onMdl
    , onShowMainMenu = Msg.onShowMainMenu
    , onEntityListKeyDown = Msg.onEntityListKeyDown
    , onStopRunningTodo = TodoMsg.onStopRunningTodo
    }


init model =
    let
        appVM =
            ViewModel.create model

        children =
            [ View.Layout.appLayoutView config appVM model
            , View.Mat.newTodoFab model
            ]
                ++ View.Overlays.overlayViews config model
    in
        div [ class "mdl-typography--body-1" ] children
