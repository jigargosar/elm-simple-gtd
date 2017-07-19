port module Main exposing (main)

import Context
import Entity.Types exposing (GroupEntityType(ContextEntity), createContextEntity)
import ExclusiveMode.Types exposing (ExclusiveMode(XMNone))
import Firebase
import Lazy
import LocalPref
import Material
import Model
import Model.EntityList
import Model.GroupDocStore
import Model.Selection
import Model.Stores
import Model.ViewType
import Project
import Random.Pcg
import Return exposing (map)
import RouteUrl
import Routes
import Set
import Time exposing (Time)
import Todo.Notification.Model
import Todo.Store
import Todo.TimeTracker
import TodoMsg
import Update
import View
import ViewModel
import X.Keyboard
import Json.Encode as E
import Msg exposing (AppMsg)
import X.Random
import Json.Encode as E
import Types exposing (..)
import Msg
import Msg.Subscription
import Ports exposing (onFirebaseDatabaseChangeSub)
import Store
import Subscriptions.AppDrawer
import Subscriptions.Firebase
import Subscriptions.Todo
import Time
import Types exposing (AppModel)
import X.Keyboard
import X.Return exposing (returnWith)
import Toolkit.Operators exposing (..)


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


type alias Flags =
    { now : Time
    , encodedTodoList : List E.Value
    , encodedProjectList : List E.Value
    , encodedContextList : List E.Value
    , pouchDBRemoteSyncURI : String
    , developmentMode : Bool
    , appVersion : String
    , deviceId : String
    , config : AppConfig
    , localPref : E.Value
    }


init : Flags -> AppReturn
init flags =
    let
        { now, encodedTodoList, encodedProjectList, encodedContextList, pouchDBRemoteSyncURI } =
            flags

        storeGenerator =
            Random.Pcg.map3 (,,)
                (Todo.Store.generator flags.deviceId encodedTodoList)
                (Project.storeGenerator flags.deviceId encodedProjectList)
                (Context.storeGenerator flags.deviceId encodedContextList)

        ( ( todoStore, projectStore, contextStore ), seed ) =
            Random.Pcg.step storeGenerator (X.Random.seedFromTime now)

        firebaseModel =
            Firebase.init flags.deviceId

        localPref =
            LocalPref.decode flags.localPref

        model : AppModel
        model =
            { now = now
            , todoStore = todoStore
            , projectStore = projectStore
            , contextStore = contextStore
            , editMode = XMNone
            , viewType = Model.ViewType.defaultView
            , keyboardState = X.Keyboard.init
            , reminderOverlay = Todo.Notification.Model.none
            , pouchDBRemoteSyncURI = pouchDBRemoteSyncURI
            , user = firebaseModel.user
            , fcmToken = firebaseModel.fcmToken
            , firebaseClient = firebaseModel.firebaseClient
            , developmentMode = flags.developmentMode
            , selectedEntityIdSet = Set.empty
            , appVersion = flags.appVersion
            , deviceId = flags.deviceId
            , focusInEntity = createContextEntity Context.null
            , timeTracker = Todo.TimeTracker.none
            , config = flags.config
            , appDrawerModel = localPref.appDrawer
            , signInModel = localPref.signIn
            , mdl = Material.model
            }
    in
        update Msg.onSwitchToNewUserSetupModeIfNeeded model


updateConfig model =
    { --model
      now = model.now
    , activeProjects = (Model.GroupDocStore.getActiveProjects model)
    , activeContexts = (Model.GroupDocStore.getActiveContexts model)
    , updateEntityListCursorOnTodoChange = map (Model.EntityList.updateEntityListCursorOnTodoChange model)
    , updateEntityListCursorOnGroupDocChange =
        map (Model.EntityList.updateEntityListCursorOnGroupDocChange model)
    , currentViewEntityListLazy =
        Lazy.lazy
            (\_ ->
                Model.EntityList.createEntityListForCurrentView model
            )

    --msg
    , clearSelection = map Model.Selection.clearSelection
    , noop = andThenUpdate Msg.noop
    , openLaunchBarMsg = andThenUpdate Msg.openLaunchBarMsg
    , revertExclusiveMode = andThenUpdate Msg.revertExclusiveMode
    , setDomFocusToFocusInEntityCmd = andThenUpdate Msg.setDomFocusToFocusInEntityCmd
    , onSaveTodoForm = Msg.onSaveTodoForm >> andThenUpdate
    , onSaveGroupDocForm = Msg.onSaveGroupDocForm >> andThenUpdate
    , onSetExclusiveMode = Msg.onSetExclusiveMode >> andThenUpdate
    , onSaveExclusiveModeForm = Msg.onSaveExclusiveModeForm |> andThenUpdate
    , onToggleContextArchived = Msg.onToggleContextArchived >> andThenUpdate
    , onToggleContextDeleted = Msg.onToggleContextDeleted >> andThenUpdate
    , onToggleProjectArchived = Msg.onToggleProjectArchived >> andThenUpdate
    , onToggleProjectDeleted = Msg.onToggleProjectDeleted >> andThenUpdate
    , switchToContextsView = Msg.switchToContextsView |> andThenUpdate
    , setFocusInEntityWithEntityId =
        (\entityId ->
            map (Model.Stores.setFocusInEntityWithEntityId entityId)
                >> andThenUpdate Msg.setDomFocusToFocusInEntityCmd
        )
    , setFocusInEntity =
        (\entity ->
            map (Model.setFocusInEntity entity)
                >> andThenUpdate Msg.setDomFocusToFocusInEntityCmd
        )
    , closeNotification = Msg.OnCloseNotification >> andThenUpdate

    -- todo msg
    , afterTodoUpsert = TodoMsg.afterTodoUpsert >> andThenUpdate
    , onStartAddingTodoWithFocusInEntityAsReference =
        andThenUpdate TodoMsg.onStartAddingTodoWithFocusInEntityAsReference
    , onStartAddingTodoToInbox = andThenUpdate TodoMsg.onStartAddingTodoToInbox
    , onToggleTodoArchived = TodoMsg.onToggleDoneAndMaybeSelection >> andThenUpdate
    , onToggleTodoDeleted = TodoMsg.onToggleDeletedAndMaybeSelection >> andThenUpdate
    , switchToEntityListView = Msg.switchToEntityListView >> andThenUpdate
    , onStartEditingTodo = TodoMsg.onStartEditingTodo >> andThenUpdate
    }


andThenUpdate =
    update >> Return.andThen


update : AppMsg -> AppModel -> AppReturn
update msg =
    Return.singleton
        >> returnWith updateConfig
            (Update.update # andThenUpdate # msg)


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
    , onUpdateCustomSyncFormUri = Msg.onUpdateCustomSyncFormUri
    , onStartCustomRemotePouchSync = Msg.onStartCustomRemotePouchSync
    , switchToEntityListView = Msg.switchToEntityListView
    , switchToView = Msg.switchToView
    , onMdl = Msg.onMdl
    , onShowMainMenu = Msg.onShowMainMenu
    , onEntityListKeyDown = Msg.onEntityListKeyDown
    , onStopRunningTodo = TodoMsg.onStopRunningTodo
    , onStartAddingTodoWithFocusInEntityAsReference = TodoMsg.onStartAddingTodoWithFocusInEntityAsReference
    }


view model =
    View.init viewConfig (ViewModel.create model) model


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
