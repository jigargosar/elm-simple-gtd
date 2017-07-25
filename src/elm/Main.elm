module Main exposing (main)

import Lazy
import Model.EntityList
import Model.Internal exposing (Flags)
import Msg exposing (AppMsg)
import Return
import RouteUrl
import Routes
import Subscriptions
import Subscriptions.AppDrawer
import Subscriptions.Firebase
import Subscriptions.Todo
import Todo.Msg
import TodoMsg
import Types exposing (..)
import Update
import View
import X.Function.Infix exposing (..)


type alias AppReturn =
    Return.Return AppMsg AppModel


subscriptions : AppModel -> Sub Msg.AppMsg
subscriptions model =
    Sub.batch
        [ Subscriptions.subscriptions |> Sub.map Msg.OnSubscriptionMsg
        , Subscriptions.Todo.subscriptions model |> Sub.map Msg.OnTodoMsg
        , Subscriptions.Firebase.subscriptions model |> Sub.map Msg.OnFirebaseMsg
        , Subscriptions.AppDrawer.subscriptions model |> Sub.map Msg.OnAppDrawerMsg
        ]


init : Flags -> AppReturn
init =
    Model.Internal.createAppModel
        >> update Msg.onSwitchToNewUserSetupModeIfNeeded


updateConfig : AppModel -> Update.Config AppMsg
updateConfig model =
    { noop = Msg.noop
    , onStartAddingTodoToInbox = TodoMsg.onStartAddingTodoToInbox
    , onStartAddingTodoWithFocusInEntityAsReference =
        TodoMsg.onStartAddingTodoWithFocusInEntityAsReference
    , openLaunchBarMsg = Msg.openLaunchBarMsg
    , afterTodoUpsert = TodoMsg.afterTodoUpsert
    , onSetExclusiveMode = Msg.onSetExclusiveMode
    , revertExclusiveMode = Msg.revertExclusiveMode
    , switchToEntityListView = Msg.switchToEntityListView
    , setDomFocusToFocusInEntityCmd = Msg.setDomFocusToFocusInEntityCmd
    , onStartEditingTodo = TodoMsg.onStartEditingTodo
    , onSaveExclusiveModeForm = Msg.onSaveExclusiveModeForm
    , onStartSetupAddTodo = TodoMsg.onStartSetupAddTodo
    , switchToContextsView = Msg.switchToContextsViewMsg
    , setFocusInEntityWithEntityId = Msg.SetFocusInEntityWithEntityId
    , setFocusInEntityMsg = Msg.SetFocusInEntity
    , currentViewEntityList =
        Lazy.lazy (\_ -> Model.EntityList.createEntityListForCurrentView model)
    , saveTodoForm = Msg.onSaveTodoForm
    , saveGroupDocForm = Msg.onSaveGroupDocForm
    , onTodoMsgWithNow = Msg.OnTodoMsgWithNow
    , onLaunchBarMsgWithNow = Msg.OnLaunchBarMsgWithNow
    , onMdl = Msg.OnMdl
    , bringEntityIdInViewMsg = Msg.bringEntityIdInViewMsg
    , onGotoRunningTodoMsg = Todo.Msg.onGotoRunningTodoMsg |> Msg.OnTodoMsg
    }


update : AppMsg -> AppModel -> AppReturn
update msg model =
    Return.singleton model |> Update.update (updateConfig model) msg


viewConfig =
    { onSetProject = Todo.Msg.onSetProjectAndMaybeSelection >>> Msg.OnTodoMsg
    , onSetContext = Todo.Msg.onSetContextAndMaybeSelection >>> Msg.OnTodoMsg
    , onSetTodoFormMenuState = Todo.Msg.onSetTodoFormMenuState >>> Msg.OnTodoMsg
    , noop = Msg.noop
    , revertExclusiveMode = Msg.revertExclusiveMode
    , onSetTodoFormText = Todo.Msg.onSetTodoFormText >>> Msg.OnTodoMsg
    , onToggleDeleted = Todo.Msg.onToggleDeleted >> Msg.OnTodoMsg
    , onSetTodoFormReminderDate = Todo.Msg.onSetTodoFormReminderDate >>> Msg.OnTodoMsg
    , onSetTodoFormReminderTime = Todo.Msg.onSetTodoFormReminderTime >>> Msg.OnTodoMsg
    , onSaveExclusiveModeForm = Msg.onSaveExclusiveModeForm
    , onEntityUpdateMsg = Msg.onEntityUpdateMsg
    , onMainMenuStateChanged = Msg.onMainMenuStateChanged
    , onSignIn = Msg.onSignIn
    , onSignOut = Msg.onSignOut
    , onLaunchBarMsg = Msg.OnLaunchBarMsg
    , onFirebaseMsg = Msg.OnFirebaseMsg
    , onReminderOverlayAction = Todo.Msg.onReminderOverlayAction >> Msg.OnTodoMsg
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
    , onStopRunningTodoMsg = Todo.Msg.onStopRunningTodoMsg |> Msg.OnTodoMsg
    , onStartAddingTodoWithFocusInEntityAsReference =
        Todo.Msg.onStartAddingTodoWithFocusInEntityAsReference |> Msg.OnTodoMsg
    , onToggleEntitySelection = Msg.onToggleEntitySelection
    , onStartEditingTodoProject = Todo.Msg.onStartEditingTodoProject >> Msg.OnTodoMsg
    , onStartEditingTodoContext = Todo.Msg.onStartEditingTodoContext >> Msg.OnTodoMsg
    , onSwitchOrStartTrackingTodo = Todo.Msg.onSwitchOrStartTrackingTodo >> Msg.OnTodoMsg
    , onStartEditingTodoText = Todo.Msg.onStartEditingTodoText >> Msg.OnTodoMsg
    , onStartEditingReminder = Todo.Msg.onStartEditingReminder >> Msg.OnTodoMsg
    , onToggleDeletedAndMaybeSelection = Todo.Msg.onToggleDeletedAndMaybeSelection >> Msg.OnTodoMsg
    , onToggleDoneAndMaybeSelection = Todo.Msg.onToggleDoneAndMaybeSelection >> Msg.OnTodoMsg
    , onToggleGroupDocArchived = Msg.onToggleGroupDocArchived
    , onGD_UpdateFormName = Msg.onGD_UpdateFormName
    , onStartEditingGroupDoc = Msg.onStartEditingGroupDoc
    , setFocusInEntityWithEntityId = Msg.SetFocusInEntityWithEntityId
    }


view model =
    View.init viewConfig model


main : RouteUrl.RouteUrlProgram Flags AppModel Msg.AppMsg
main =
    RouteUrl.programWithFlags
        { delta2url = Routes.delta2hash
        , location2messages = Routes.hash2messages viewConfig
        , init = init
        , update = update
        , view = view
        , subscriptions = subscriptions
        }
