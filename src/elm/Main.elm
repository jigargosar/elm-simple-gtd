port module Main exposing (main)

import Model.Internal exposing (Flags)
import Return
import RouteUrl
import Routes
import Time exposing (Time)
import TodoMsg
import Update
import View
import X.Keyboard
import Msg exposing (AppMsg)
import Types exposing (..)
import Msg.Subscription
import Ports exposing (onFirebaseDatabaseChangeSub)
import Store
import Subscriptions.AppDrawer
import Subscriptions.Firebase
import Subscriptions.Todo
import Time
import Types exposing (AppModel)
import X.Keyboard


type alias AppReturn =
    Return.Return AppMsg AppModel


subscriptions : AppModel -> Sub Msg.AppMsg
subscriptions model =
    Sub.batch
        [ Sub.batch
            [ Time.every (Time.second * 1) Msg.Subscription.OnNowChanged
            , X.Keyboard.subscription Msg.Subscription.OnKeyboardMsg
            , X.Keyboard.ups Msg.Subscription.OnGlobalKeyUp
            , Store.onChange Msg.Subscription.OnPouchDBChange
            , onFirebaseDatabaseChangeSub Msg.Subscription.OnFirebaseDatabaseChange
            ]
            |> Sub.map Msg.OnSubscriptionMsg
        , Subscriptions.Todo.subscriptions model |> Sub.map Msg.OnTodoMsg
        , Subscriptions.Firebase.subscriptions model |> Sub.map Msg.OnFirebaseMsg
        , Subscriptions.AppDrawer.subscriptions model |> Sub.map Msg.OnAppDrawerMsg
        ]


init : Flags -> AppReturn
init =
    Model.Internal.createAppModel
        >> update Msg.onSwitchToNewUserSetupModeIfNeeded


update : AppMsg -> AppModel -> AppReturn
update msg =
    let
        andThenUpdate =
            update >> Return.andThen
    in
        Return.singleton
            >> Update.update andThenUpdate msg


viewConfig =
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
    , onAppDrawerMsg = Msg.onAppDrawerMsg
    , onStartAddingGroupDoc = Msg.onStartAddingGroupDoc
    , onUpdateCustomSyncFormUri = Msg.onUpdateCustomSyncFormUri
    , onStartCustomRemotePouchSync = Msg.onStartCustomRemotePouchSync
    , switchToEntityListView = Msg.switchToEntityListView
    , switchToView = Msg.switchToView
    , onMdl = Msg.onMdl
    , onShowMainMenu = Msg.onShowMainMenu
    , onEntityListKeyDown = Msg.onEntityListKeyDown
    , onStopRunningTodo = TodoMsg.onStopRunningTodo
    , onStartAddingTodoWithFocusInEntityAsReference =
        TodoMsg.onStartAddingTodoWithFocusInEntityAsReference
    , onToggleEntitySelection = Msg.onToggleEntitySelection
    , onStartEditingTodoProject = TodoMsg.onStartEditingTodoProject
    , onStartEditingTodoContext = TodoMsg.onStartEditingTodoContext
    , onSwitchOrStartTrackingTodo = TodoMsg.onSwitchOrStartTrackingTodo
    , onStartEditingTodoText = TodoMsg.onStartEditingTodoText
    , onStartEditingReminder = TodoMsg.onStartEditingReminder
    , onToggleDeletedAndMaybeSelection = TodoMsg.onToggleDeletedAndMaybeSelection
    , onToggleDoneAndMaybeSelection = TodoMsg.onToggleDoneAndMaybeSelection
    , onToggleGroupDocArchived = Msg.onToggleGroupDocArchived
    , onGD_UpdateFormName = Msg.onGD_UpdateFormName
    }


view model =
    View.init viewConfig model


main : RouteUrl.RouteUrlProgram Flags AppModel Msg.AppMsg
main =
    RouteUrl.programWithFlags
        { delta2url = Routes.delta2hash
        , location2messages = Routes.hash2messages
        , init = init
        , update = update
        , view = view
        , subscriptions = subscriptions
        }
