module Main exposing (main)

import AppDrawer.Model
import AppDrawer.Types exposing (AppDrawerMsg(..))
import Context
import Entity.ListView
import Entity.Types exposing (..)
import EntityListCursor exposing (HasEntityListCursor)
import ExclusiveMode.Types exposing (..)
import Firebase exposing (..)
import Html exposing (Html)
import Json.Encode as E
import Keyboard
import Keyboard.Extra as KX exposing (Key)
import LocalPref
import Mat exposing (cs)
import Material
import Material.Options exposing (div)
import Menu
import Menu.Types
import Msg.AppHeader exposing (AppHeaderMsg(..))
import Msg.CustomSync exposing (CustomSyncMsg(..))
import Msg.ExclusiveMode exposing (ExclusiveModeMsg)
import Msg.Firebase exposing (..)
import Msg.GroupDoc exposing (GroupDocMsg)
import Overlays.LaunchBar exposing (LaunchBarMsg)
import Page exposing (Page(EntityListPage), PageMsg(..))
import Pages.EntityList exposing (..)
import Ports
import Ports.Firebase exposing (..)
import Ports.Todo exposing (..)
import Project
import Random.Pcg
import RouteUrl
import Set exposing (Set)
import Time exposing (Time)
import Todo.FormTypes
import Todo.Msg exposing (..)
import Todo.Notification.Model
import Todo.Notification.Types exposing (TodoReminderOverlayModel)
import Todo.Store
import Todo.TimeTracker
import Toolkit.Operators exposing (..)
import Types.Document exposing (..)
import Types.Firebase exposing (..)
import Types.GroupDoc exposing (..)
import Types.Todo exposing (..)
import Update.AppDrawer
import Update.AppHeader
import Update.CustomSync
import Update.Entity
import Update.ExclusiveMode
import Update.Firebase
import Update.GroupDoc
import Update.LaunchBar
import Update.Page
import Update.Subscription
import Update.Todo
import View.CustomSync
import View.Layout
import View.NewTodoFab exposing (newTodoFab)
import View.Overlays
import ViewModel
import Window
import X.Function exposing (..)
import X.Function.Infix exposing (..)
import X.Random
import X.Return exposing (..)


type alias AppConfig =
    { debugSecondMultiplier : Float
    , deviceId : String
    , npmPackageVersion : String
    , isDevelopmentMode : Bool
    , debug : Bool
    }


type alias AppModel =
    HasEntityListCursor AppModelOtherFields


type alias AppModelOtherFields =
    { lastKnownCurrentTime : Time
    , todoStore : TodoStore
    , projectStore : ProjectStore
    , contextStore : ContextStore
    , editMode : ExclusiveMode
    , page : Page
    , reminderOverlay : TodoReminderOverlayModel
    , pouchDBRemoteSyncURI : String
    , firebaseModel : FirebaseModel
    , developmentMode : Bool
    , selectedEntityIdSet : Set DocId
    , appVersion : String
    , deviceId : String
    , timeTracker : Todo.TimeTracker.Model
    , config : AppConfig
    , appDrawerModel : AppDrawer.Model.AppDrawerModel
    , mdl : Material.Model
    }


type SubscriptionMsg
    = OnPouchDBChange String E.Value
    | OnFirebaseDatabaseChange String E.Value


type AppMsg
    = NOOP
    | OnSubscriptionMsg SubscriptionMsg
    | OnPageMsg PageMsg
    | OnExclusiveModeMsg ExclusiveModeMsg
    | OnAppHeaderMsg AppHeaderMsg
    | OnCustomSyncMsg CustomSyncMsg
    | OnEntityMsg Entity.Types.EntityMsg
    | OnLaunchBarMsg LaunchBarMsg
    | OnLaunchBarMsgWithNow LaunchBarMsg Time
    | OnGroupDocMsg GroupDocMsg
    | OnGroupDocMsgWithNow GroupDocMsg Time
    | OnTodoMsg TodoMsg
    | OnTodoMsgWithNow TodoMsg Time
    | OnFirebaseMsg FirebaseMsg
    | OnAppDrawerMsg AppDrawer.Types.AppDrawerMsg
    | OnMdl (Material.Msg AppMsg)
    | OnGlobalKeyUp Int
    | OnGlobalKeyDown Int
    | SetLastKnownTimeStamp Time


onStartAddingTodoWithFocusInEntityAsReference : AppModel -> AppMsg
onStartAddingTodoWithFocusInEntityAsReference model =
    EntityListCursor.computeMaybeNewEntityIdAtCursor model
        |> Todo.Msg.onStartAddingTodoWithFocusInEntityAsReference
        |> OnTodoMsg


gotoEntityListPageMsg =
    PageMsg_SetEntityListPage >> OnPageMsg


revertExclusiveModeMsg =
    Msg.ExclusiveMode.OnSetExclusiveModeToNoneAndTryRevertingFocus
        |> OnExclusiveModeMsg


onSaveExclusiveModeForm : AppMsg
onSaveExclusiveModeForm =
    Msg.ExclusiveMode.OnSaveExclusiveModeForm |> OnExclusiveModeMsg


setFocusInEntityWithEntityIdMsg : EntityId -> AppMsg
setFocusInEntityWithEntityIdMsg =
    EM_SetFocusInEntityWithEntityId >> OnEntityMsg


subscriptions : AppModel -> Sub AppMsg
subscriptions model =
    let
        everyXSeconds x =
            Time.every (Time.second * x * debugSecondMultiplier)

        debugSecondMultiplier =
            if model.config.debug then
                60
            else
                1
    in
    Sub.batch
        [ Keyboard.ups OnGlobalKeyUp
        , Keyboard.downs OnGlobalKeyDown
        , everyXSeconds 1 SetLastKnownTimeStamp
        , Sub.batch
            [ Ports.pouchDBChanges (uncurry OnPouchDBChange)
            , Ports.onFirebaseDatabaseChange (uncurry OnFirebaseDatabaseChange)
            ]
            |> Sub.map OnSubscriptionMsg
        , Sub.batch
            [ notificationClicked OnReminderNotificationClicked
            , onRunningTodoNotificationClicked RunningNotificationResponse
            , everyXSeconds 1 (\_ -> UpdateTimeTracker)

            -- note: 30 seconds is so that we can received any updates from firebase
            -- before triggering and changing any stale overdue todos timestamps.
            , everyXSeconds 30 (\_ -> OnProcessPendingNotificationCronTick)
            ]
            |> Sub.map OnTodoMsg
        , Sub.batch
            [ onFirebaseUserChanged OnFBUserChanged
            , onFCMTokenChanged OnFBFCMTokenChanged
            , onFirebaseConnectionChanged OnFBConnectionChanged
            ]
            |> Sub.map OnFirebaseMsg
        , Sub.batch
            [ Window.resizes (\_ -> OnWindowResizeTurnOverlayOff) ]
            |> Sub.map OnAppDrawerMsg
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


createAppModel : Flags -> AppModel
createAppModel flags =
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

        localPref =
            LocalPref.decode flags.localPref

        model : AppModel
        model =
            { lastKnownCurrentTime = now
            , todoStore = todoStore
            , projectStore = projectStore
            , contextStore = contextStore
            , editMode = XMNone
            , page = Page.initialPage
            , reminderOverlay = Todo.Notification.Model.none
            , pouchDBRemoteSyncURI = pouchDBRemoteSyncURI
            , firebaseModel =
                Firebase.init flags.deviceId localPref.signIn
            , developmentMode = flags.developmentMode
            , selectedEntityIdSet = Set.empty
            , appVersion = flags.appVersion
            , deviceId = flags.deviceId
            , timeTracker = Todo.TimeTracker.none
            , config = flags.config
            , appDrawerModel = localPref.appDrawer
            , mdl = Material.model
            , entityListCursor = EntityListCursor.initialValue

            --            , sequencer = sequencerInitialValue
            }
    in
    model


type alias UpdateConfig msg =
    Update.LaunchBar.Config msg (Update.AppHeader.Config msg (Update.ExclusiveMode.Config msg (Update.Page.Config msg (Update.Firebase.Config msg (Update.CustomSync.Config msg (Update.Entity.Config msg (Update.Subscription.Config msg (Update.Todo.Config msg {}))))))))


updateConfig : AppModel -> UpdateConfig AppMsg
updateConfig model =
    { onStartAddingTodoToInbox = Todo.Msg.onStartAddingTodoToInbox |> OnTodoMsg
    , onStartAddingTodoWithFocusInEntityAsReference =
        onStartAddingTodoWithFocusInEntityAsReference model
    , openLaunchBarMsg = Overlays.LaunchBar.Open |> OnLaunchBarMsg
    , afterTodoUpsert = Todo.Msg.afterTodoUpsert >> OnTodoMsg
    , onSetExclusiveMode = Msg.ExclusiveMode.OnSetExclusiveMode >> OnExclusiveModeMsg
    , revertExclusiveMode = revertExclusiveModeMsg
    , gotoEntityListPageMsg = gotoEntityListPageMsg
    , onStartEditingTodo = Todo.Msg.onStartEditingTodo >> OnTodoMsg
    , onSaveExclusiveModeForm = onSaveExclusiveModeForm
    , onStartSetupAddTodo = Todo.Msg.onStartSetupAddTodo |> OnTodoMsg
    , setFocusInEntityWithEntityId = setFocusInEntityWithEntityIdMsg
    , saveTodoForm = Todo.Msg.OnSaveTodoForm >> OnTodoMsg
    , saveGroupDocForm = Msg.GroupDoc.OnSaveGroupDocForm >> OnGroupDocMsg
    , bringEntityIdInViewMsg = EM_Update # EUA_BringEntityIdInView >> OnEntityMsg
    , onGotoRunningTodoMsg = Todo.Msg.onGotoRunningTodoMsg |> OnTodoMsg
    , focusNextEntityMsg = OnEntityMsg Entity.Types.EM_EntityListFocusNext
    , focusPrevEntityMsg = OnEntityMsg Entity.Types.EM_EntityListFocusPrev

    --    , maybeEntityIdAtCursor = EntityListCursor.getMaybeEntityIdAtCursor model
    }


update : UpdateConfig AppMsg -> AppMsg -> ReturnF AppMsg AppModel
update config msg =
    let
        onPersistLocalPref =
            effect (LocalPref.encodeLocalPref >> Ports.persistLocalPref)
    in
    case msg of
        NOOP ->
            identity

        OnMdl msg_ ->
            andThen (Material.update OnMdl msg_)

        OnGlobalKeyUp keyCode ->
            Update.Subscription.onGlobalKeyUp config (KX.fromCode keyCode)

        OnGlobalKeyDown keyCode ->
            Update.Subscription.onGlobalKeyDown config (KX.fromCode keyCode)

        SetLastKnownTimeStamp now ->
            map (\model -> { model | lastKnownCurrentTime = now })

        OnPageMsg msg_ ->
            Update.Page.update config msg_

        OnSubscriptionMsg msg_ ->
            onSubscriptionMsg config msg_

        OnGroupDocMsg msg_ ->
            returnWithNow (OnGroupDocMsgWithNow msg_)

        OnGroupDocMsgWithNow msg_ now ->
            Update.GroupDoc.update config now msg_

        OnExclusiveModeMsg msg_ ->
            Update.ExclusiveMode.update config msg_

        OnAppHeaderMsg msg_ ->
            Update.AppHeader.update config msg_

        OnCustomSyncMsg msg_ ->
            Update.CustomSync.update config msg_

        OnEntityMsg msg_ ->
            Update.Entity.update config msg_

        OnLaunchBarMsgWithNow msg_ now ->
            Update.LaunchBar.update config now msg_

        OnLaunchBarMsg msg_ ->
            returnWithNow (OnLaunchBarMsgWithNow msg_)

        OnTodoMsg msg_ ->
            returnWithNow (OnTodoMsgWithNow msg_)

        OnTodoMsgWithNow msg_ now ->
            Update.Todo.update config now msg_

        OnFirebaseMsg msg_ ->
            Update.Firebase.update config msg_
                >> onPersistLocalPref

        OnAppDrawerMsg msg ->
            Update.AppDrawer.update msg
                >> onPersistLocalPref


onSubscriptionMsg config msg =
    case msg of
        OnPouchDBChange dbName encodedDoc ->
            Update.Subscription.onPouchDBChange config dbName encodedDoc

        OnFirebaseDatabaseChange dbName encodedDoc ->
            effect (Update.Subscription.upsertEncodedDocOnFirebaseDatabaseChange dbName encodedDoc)


type alias ViewConfig msg =
    { noop : msg
    , onEntityUpdateMsg : EntityId -> EntityUpdateAction -> msg
    , onAppDrawerMsg : AppDrawer.Types.AppDrawerMsg -> msg
    , onFirebaseMsg : FirebaseMsg -> msg
    , onLaunchBarMsg : Overlays.LaunchBar.LaunchBarMsg -> msg
    , onMainMenuStateChanged : Menu.Types.MenuState -> msg
    , onMdl : Material.Msg msg -> msg
    , onReminderOverlayAction : Todo.Notification.Model.Action -> msg
    , onSaveExclusiveModeForm : msg
    , onSetContext : DocId -> ContextDoc -> msg
    , onSetProject : DocId -> ProjectDoc -> msg
    , onSetTodoFormMenuState : Todo.FormTypes.TodoForm -> Menu.State -> msg
    , onSetTodoFormReminderDate : Todo.FormTypes.TodoForm -> String -> msg
    , onSetTodoFormReminderTime : Todo.FormTypes.TodoForm -> String -> msg
    , onSetTodoFormText : Todo.FormTypes.TodoForm -> String -> msg
    , onShowMainMenu : msg
    , onSignIn : msg
    , onSignOut : msg
    , onStartAddingGroupDoc : GroupDocType -> msg
    , onStartAddingTodoWithFocusInEntityAsReference : msg
    , onStartCustomRemotePouchSync : ExclusiveMode.Types.SyncForm -> msg
    , onStartEditingGroupDoc : GroupDocId -> msg
    , onStartEditingReminder : TodoDoc -> msg
    , onStartEditingTodoContext : TodoDoc -> msg
    , onStartEditingTodoProject : TodoDoc -> msg
    , onStartEditingTodoText : TodoDoc -> msg
    , onStopRunningTodoMsg : msg
    , onSwitchOrStartTrackingTodo : DocId -> msg
    , onToggleAppDrawerOverlay : msg
    , onToggleDeleted : DocId -> msg
    , onToggleDeletedAndMaybeSelection : DocId -> msg
    , onToggleDoneAndMaybeSelection : DocId -> msg
    , onToggleEntitySelection : Entity.Types.EntityId -> msg
    , onToggleGroupDocArchived : GroupDocId -> msg
    , onUpdateCustomSyncFormUri :
        ExclusiveMode.Types.SyncForm -> String -> msg
    , revertExclusiveMode : msg
    , setFocusInEntityWithEntityId : Entity.Types.EntityId -> msg
    , updateGroupDocFromNameMsg :
        GroupDocForm -> GroupDocName -> msg
    , gotoEntityListPageMsg : EntityListPageModel -> msg
    , gotoPageMsg : Page.Page -> msg
    , maybeEntityIdAtCursor : Maybe EntityId
    , navigateToPathMsg : List String -> msg
    }


viewConfig : AppModel -> ViewConfig AppMsg
viewConfig model =
    { onSetProject = Todo.Msg.onSetProjectAndMaybeSelection >>> OnTodoMsg
    , onSetContext = Todo.Msg.onSetContextAndMaybeSelection >>> OnTodoMsg
    , onSetTodoFormMenuState = Todo.Msg.onSetTodoFormMenuState >>> OnTodoMsg
    , noop = NOOP
    , revertExclusiveMode = revertExclusiveModeMsg
    , onSetTodoFormText = Todo.Msg.onSetTodoFormText >>> OnTodoMsg
    , onToggleDeleted = Todo.Msg.onToggleDeleted >> OnTodoMsg
    , onSetTodoFormReminderDate = Todo.Msg.onSetTodoFormReminderDate >>> OnTodoMsg
    , onSetTodoFormReminderTime = Todo.Msg.onSetTodoFormReminderTime >>> OnTodoMsg
    , onSaveExclusiveModeForm = onSaveExclusiveModeForm
    , onEntityUpdateMsg = Entity.Types.EM_Update >>> OnEntityMsg
    , onMainMenuStateChanged = OnMainMenuStateChanged >> OnAppHeaderMsg
    , onSignIn = OnFirebaseMsg OnFBSignIn
    , onSignOut = OnFirebaseMsg OnFBSignOut
    , onLaunchBarMsg = OnLaunchBarMsg
    , onFirebaseMsg = OnFirebaseMsg
    , onReminderOverlayAction = Todo.Msg.onReminderOverlayAction >> OnTodoMsg
    , onToggleAppDrawerOverlay = OnAppDrawerMsg AppDrawer.Types.OnToggleOverlay
    , onAppDrawerMsg = OnAppDrawerMsg
    , onStartAddingGroupDoc = Msg.GroupDoc.OnGroupDocAction # GDA_StartAdding >> OnGroupDocMsg
    , onUpdateCustomSyncFormUri = OnUpdateCustomSyncFormUri >>> OnCustomSyncMsg
    , onStartCustomRemotePouchSync = OnStartCustomSync >> OnCustomSyncMsg
    , gotoEntityListPageMsg = gotoEntityListPageMsg
    , gotoPageMsg = PageMsg_SetPage >> OnPageMsg
    , onMdl = OnMdl
    , onShowMainMenu = OnShowMainMenu |> OnAppHeaderMsg
    , onStopRunningTodoMsg = Todo.Msg.onStopRunningTodoMsg |> OnTodoMsg
    , onStartAddingTodoWithFocusInEntityAsReference =
        onStartAddingTodoWithFocusInEntityAsReference model
    , onToggleEntitySelection = EM_Update # EUA_ToggleSelection >> OnEntityMsg
    , onStartEditingTodoProject = Todo.Msg.onStartEditingTodoProject >> OnTodoMsg
    , onStartEditingTodoContext = Todo.Msg.onStartEditingTodoContext >> OnTodoMsg
    , onSwitchOrStartTrackingTodo = Todo.Msg.onSwitchOrStartTrackingTodo >> OnTodoMsg
    , onStartEditingTodoText = Todo.Msg.onStartEditingTodoText >> OnTodoMsg
    , onStartEditingReminder = Todo.Msg.onStartEditingReminder >> OnTodoMsg
    , onToggleDeletedAndMaybeSelection = Todo.Msg.onToggleDeletedAndMaybeSelection >> OnTodoMsg
    , onToggleDoneAndMaybeSelection = Todo.Msg.onToggleDoneAndMaybeSelection >> OnTodoMsg
    , onToggleGroupDocArchived = Msg.GroupDoc.onToggleGroupDocArchived >> OnGroupDocMsg
    , updateGroupDocFromNameMsg =
        Msg.GroupDoc.updateGroupDocFromNameMsg >>> OnGroupDocMsg
    , onStartEditingGroupDoc = Msg.GroupDoc.onStartEditingGroupDoc >> OnGroupDocMsg
    , setFocusInEntityWithEntityId = setFocusInEntityWithEntityIdMsg
    , maybeEntityIdAtCursor = EntityListCursor.computeMaybeNewEntityIdAtCursor model
    , navigateToPathMsg = PageMsg_NavigateToPath >> OnPageMsg
    }


view : ViewConfig msg -> AppModel -> Html msg
view config model =
    let
        appVM =
            ViewModel.create config model

        frame pageContent =
            div [ cs "mdl-typography--body-1" ]
                ([ View.Layout.appLayoutView config appVM model pageContent
                 , newTodoFab config model
                 ]
                    ++ View.Overlays.overlayViews config model
                )
    in
    case Page.getPage__ model of
        Page.EntityListPage entityListPageModel ->
            Entity.ListView.listView config appVM entityListPageModel model
                |> frame

        Page.CustomSyncSettingsPage ->
            View.CustomSync.view config model
                |> frame


main : RouteUrl.RouteUrlProgram Flags AppModel AppMsg
main =
    let
        init =
            createAppModel
                >> update_ (OnFirebaseMsg OnFB_SwitchToNewUserSetupModeIfNeeded)

        update_ : AppMsg -> AppModel -> ( AppModel, Cmd AppMsg )
        update_ msg model =
            model |> pure >> update (updateConfig model) msg
    in
    RouteUrl.programWithFlags
        { delta2url = Page.delta2hash
        , location2messages =
            Page.hash2messages
                { gotoPageMsg = PageMsg_SetPage >> OnPageMsg
                , gotoEntityListPageMsg = gotoEntityListPageMsg
                , navigateToPathMsg = PageMsg_NavigateToPath >> OnPageMsg
                }
        , init = init
        , update = update_
        , view = \model -> view (viewConfig model) model
        , subscriptions = subscriptions
        }
