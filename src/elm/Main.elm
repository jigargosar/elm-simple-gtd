module Main exposing (main)

import AppDrawer.Model
import AppDrawer.Types exposing (AppDrawerMsg(..))
import CommonMsg
import CommonMsg.Types
import Context
import Entity.ListView
import Entity.Types exposing (..)
import EntityListCursor exposing (HasEntityListCursor)
import ExclusiveMode.Types exposing (..)
import Firebase exposing (..)
import Firebase.SignIn
import GroupDoc
import Json.Encode as E
import Keyboard
import Keyboard.Extra as KX exposing (Key)
import LaunchBar.Messages exposing (LaunchBarMsg)
import LocalPref
import Mat exposing (cs)
import Material
import Material.Options exposing (div)
import Menu
import Menu.Types
import Models.Selection
import Msg.AppHeader exposing (AppHeaderMsg(..))
import Msg.CustomSync exposing (CustomSyncMsg(..))
import Msg.ExclusiveMode exposing (ExclusiveModeMsg)
import Msg.Firebase exposing (..)
import Msg.GroupDoc exposing (GroupDocMsg)
import Page exposing (Page(EntityListPage), PageMsg(..))
import Pages.EntityList exposing (..)
import Ports
import Ports.Firebase exposing (..)
import Ports.Todo exposing (..)
import Project
import Random.Pcg
import RouteUrl
import Routes
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
import X.Function.Infix exposing (..)
import X.Random
import X.Record exposing (..)
import X.Return exposing (..)


type alias SequencerModel msg =
    { list : List msg
    }


sequencerInitialValue : SequencerModel msg
sequencerInitialValue =
    { list = [] }


sequencerAppendToSequence msg =
    \model -> { model | list = model.list ++ [ msg ] }


sequencerProcessSequence : ReturnF msg (SequencerModel msg)
sequencerProcessSequence =
    returnWithMaybe1 (.list >> List.head) returnMsgAsCmd
        >> map (\model -> { model | list = List.drop 1 model.list })


type alias AppConfig =
    { debugSecondMultiplier : Float
    , deviceId : String
    , npmPackageVersion : String
    , isDevelopmentMode : Bool
    }


type alias AppModel =
    HasEntityListCursor AppModelOtherFields


type alias AppModelOtherFields =
    { now : Time
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
    , sequencer : SequencerModel AppMsg
    }


sequencer =
    fieldLens .sequencer (\s b -> { b | sequencer = s })


appendToSequence msg =
    map (over sequencer (sequencerAppendToSequence msg))


type SubscriptionMsg
    = OnNowChanged Time
    | OnPouchDBChange String E.Value
    | OnFirebaseDatabaseChange String E.Value


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
    | OnAppDrawerMsg AppDrawer.Types.AppDrawerMsg
    | Mdl (Material.Msg AppMsg)
    | OnGlobalKeyUp Int
    | OnGlobalKeyDown Int



-- common


commonMsg =
    CommonMsg.createHelper OnCommonMsg


noop =
    commonMsg.noOp



--  view type


switchToEntityListPageMsg =
    SwitchToEntityListView >> OnPageMsg



-- ex mode


revertExclusiveModeMsg =
    Msg.ExclusiveMode.OnSetExclusiveModeToNoneAndTryRevertingFocus
        |> OnExclusiveModeMsg


onSaveExclusiveModeForm =
    Msg.ExclusiveMode.OnSaveExclusiveModeForm |> OnExclusiveModeMsg



-- entityMsg


setFocusInEntityWithEntityIdMsg =
    EM_SetFocusInEntityWithEntityId >> OnEntityMsg



--drawer


onToggleAppDrawerOverlay =
    OnAppDrawerMsg AppDrawer.Types.OnToggleOverlay


onAppDrawerMsg =
    OnAppDrawerMsg



-- mdl


onMdl =
    Mdl


subscriptions model =
    let
        everyXSeconds x =
            Time.every (Time.second * x * model.config.debugSecondMultiplier)
    in
    Sub.batch
        [ Keyboard.ups OnGlobalKeyUp
        , Keyboard.downs OnGlobalKeyDown
        , Sub.batch
            [ everyXSeconds 1 OnNowChanged
            , Ports.pouchDBChanges (uncurry OnPouchDBChange)
            , Ports.onFirebaseDatabaseChange (uncurry OnFirebaseDatabaseChange)
            ]
            |> Sub.map OnSubscriptionMsg
        , Sub.batch
            [ notificationClicked OnReminderNotificationClicked
            , onRunningTodoNotificationClicked RunningNotificationResponse
            , everyXSeconds 1 (\_ -> UpdateTimeTracker)
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
            { now = now
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
            , sequencer = sequencerInitialValue
            }
    in
    model


type alias UpdateConfig msg =
    Update.LaunchBar.Config msg (Update.AppHeader.Config msg (Update.ExclusiveMode.Config msg (Update.Page.Config msg (Update.Firebase.Config msg (Update.CustomSync.Config msg (Update.Entity.Config msg (Update.Subscription.Config msg (Update.Todo.Config msg {}))))))))


updateConfig : UpdateConfig AppMsg
updateConfig =
    { onStartAddingTodoToInbox = Todo.Msg.onStartAddingTodoToInbox |> OnTodoMsg
    , onStartAddingTodoWithFocusInEntityAsReference =
        Todo.Msg.onStartAddingTodoWithFocusInEntityAsReference |> OnTodoMsg
    , openLaunchBarMsg = LaunchBar.Messages.Open |> OnLaunchBarMsg
    , afterTodoUpsert = Todo.Msg.afterTodoUpsert >> OnTodoMsg
    , onSetExclusiveMode = Msg.ExclusiveMode.OnSetExclusiveMode >> OnExclusiveModeMsg
    , revertExclusiveMode = revertExclusiveModeMsg
    , switchToEntityListPageMsg = switchToEntityListPageMsg
    , onStartEditingTodo = Todo.Msg.onStartEditingTodo >> OnTodoMsg
    , onSaveExclusiveModeForm = onSaveExclusiveModeForm
    , onStartSetupAddTodo = Todo.Msg.onStartSetupAddTodo |> OnTodoMsg
    , setFocusInEntityWithEntityId = setFocusInEntityWithEntityIdMsg
    , saveTodoForm = Todo.Msg.OnSaveTodoForm >> OnTodoMsg
    , saveGroupDocForm = Msg.GroupDoc.OnSaveGroupDocForm >> OnGroupDocMsg
    , bringEntityIdInViewMsg = EM_Update # EUA_BringEntityIdInView >> OnEntityMsg
    , onGotoRunningTodoMsg = Todo.Msg.onGotoRunningTodoMsg |> OnTodoMsg
    }


update : AppMsg -> ReturnF AppMsg AppModel
update msg =
    let
        config =
            updateConfig

        onPersistLocalPref =
            effect (LocalPref.encodeLocalPref >> Ports.persistLocalPref)

        updateEntityListCursorMsg =
            OnEntityMsg EM_UpdateEntityListCursor
    in
    (case msg of
        Mdl msg_ ->
            andThen (Material.update Mdl msg_)

        OnGlobalKeyUp keyCode ->
            onGlobalKeyUp config (KX.fromCode keyCode)

        OnGlobalKeyDown keyCode ->
            onGlobalKeyDown config (KX.fromCode keyCode)

        OnPageMsg msg_ ->
            Update.Page.update config msg_

        OnCommonMsg msg_ ->
            CommonMsg.update msg_

        OnSubscriptionMsg msg_ ->
            onSubscriptionMsg config msg_

        OnGroupDocMsg msg_ ->
            Update.GroupDoc.update config msg_
                >> returnMsgAsCmd updateEntityListCursorMsg

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
                >> returnMsgAsCmd updateEntityListCursorMsg

        OnFirebaseMsg msg_ ->
            Update.Firebase.update config msg_
                >> onPersistLocalPref

        OnAppDrawerMsg msg ->
            Update.AppDrawer.update msg
                >> onPersistLocalPref
    )
        >> overReturnF sequencer sequencerProcessSequence


onSubscriptionMsg config msg =
    case msg of
        OnNowChanged now ->
            let
                setNow now model =
                    { model | now = now }
            in
            map (setNow now)

        OnPouchDBChange dbName encodedDoc ->
            Update.Subscription.onPouchDBChange config dbName encodedDoc

        OnFirebaseDatabaseChange dbName encodedDoc ->
            effect (Update.Subscription.upsertEncodedDocOnFirebaseDatabaseChange dbName encodedDoc)


onGlobalKeyDown config key =
    let
        onEditModeNone =
            case key of
                KX.ArrowUp ->
                    OnEntityMsg Entity.Types.EM_EntityListFocusPrev
                        |> appendToSequence

                KX.ArrowDown ->
                    OnEntityMsg Entity.Types.EM_EntityListFocusNext
                        |> appendToSequence

                _ ->
                    identity
    in
    (\editMode ->
        case editMode of
            XMNone ->
                onEditModeNone

            _ ->
                identity
    )
        |> returnWith .editMode


onGlobalKeyUp config key =
    let
        clear =
            map Models.Selection.clearSelection
                >> returnMsgAsCmd config.revertExclusiveMode

        onEditModeNone =
            case key of
                KX.Escape ->
                    clear

                KX.CharX ->
                    clear

                KX.CharQ ->
                    returnMsgAsCmd
                        config.onStartAddingTodoWithFocusInEntityAsReference

                KX.CharI ->
                    returnMsgAsCmd config.onStartAddingTodoToInbox

                KX.Slash ->
                    returnMsgAsCmd config.openLaunchBarMsg

                KX.CharT ->
                    returnMsgAsCmd config.onGotoRunningTodoMsg

                _ ->
                    identity
    in
    (\editMode ->
        case ( key, editMode ) of
            ( _, XMNone ) ->
                onEditModeNone

            ( KX.Escape, _ ) ->
                returnMsgAsCmd config.revertExclusiveMode

            _ ->
                identity
    )
        |> returnWith .editMode


type alias ViewConfig msg =
    { noop : msg
    , onEntityUpdateMsg : EntityId -> EntityUpdateAction -> msg
    , onAppDrawerMsg : AppDrawer.Types.AppDrawerMsg -> msg
    , onFirebaseMsg : FirebaseMsg -> msg
    , onLaunchBarMsg : LaunchBar.Messages.LaunchBarMsg -> msg
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
    , switchToEntityListPageMsg : EntityListPageModel -> msg
    , gotoPageMsg : Page.Page -> msg
    }


viewConfig : ViewConfig AppMsg
viewConfig =
    { onSetProject = Todo.Msg.onSetProjectAndMaybeSelection >>> OnTodoMsg
    , onSetContext = Todo.Msg.onSetContextAndMaybeSelection >>> OnTodoMsg
    , onSetTodoFormMenuState = Todo.Msg.onSetTodoFormMenuState >>> OnTodoMsg
    , noop = noop
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
    , onToggleAppDrawerOverlay = onToggleAppDrawerOverlay
    , onAppDrawerMsg = onAppDrawerMsg
    , onStartAddingGroupDoc = Msg.GroupDoc.OnGroupDocAction # GDA_StartAdding >> OnGroupDocMsg
    , onUpdateCustomSyncFormUri = OnUpdateCustomSyncFormUri >>> OnCustomSyncMsg
    , onStartCustomRemotePouchSync = OnStartCustomSync >> OnCustomSyncMsg
    , switchToEntityListPageMsg = switchToEntityListPageMsg
    , gotoPageMsg = SwitchView >> OnPageMsg
    , onMdl = onMdl
    , onShowMainMenu = OnShowMainMenu |> OnAppHeaderMsg
    , onStopRunningTodoMsg = Todo.Msg.onStopRunningTodoMsg |> OnTodoMsg
    , onStartAddingTodoWithFocusInEntityAsReference =
        Todo.Msg.onStartAddingTodoWithFocusInEntityAsReference |> OnTodoMsg
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
    }


view config model =
    let
        appVM =
            ViewModel.create config model

        pageContent =
            case Page.getPage model of
                Page.EntityListPage entityListPageModel ->
                    Entity.ListView.listView config appVM entityListPageModel model

                Page.CustomSyncSettingsPage ->
                    View.CustomSync.view config model

        children =
            [ View.Layout.appLayoutView config appVM model pageContent
            , newTodoFab config model
            ]
                ++ View.Overlays.overlayViews config model
    in
    div [ cs "mdl-typography--body-1" ] children


main : RouteUrl.RouteUrlProgram Flags AppModel AppMsg
main =
    let
        init =
            createAppModel
                >> update_ (OnFirebaseMsg OnFB_SwitchToNewUserSetupModeIfNeeded)

        update_ : AppMsg -> AppModel -> ( AppModel, Cmd AppMsg )
        update_ msg model =
            model |> pure >> update msg
    in
    RouteUrl.programWithFlags
        { delta2url = Routes.delta2hash
        , location2messages = Routes.hash2messages viewConfig
        , init = init
        , update = update_
        , view = view viewConfig
        , subscriptions = subscriptions
        }
