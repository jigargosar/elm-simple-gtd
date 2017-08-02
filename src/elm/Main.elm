module Main exposing (main)

import AppDrawer.Model
import AppDrawer.Types exposing (AppDrawerMsg(..))
import Entity exposing (..)
import EntityListCursor exposing (HasEntityListCursor)
import ExclusiveMode.Types exposing (..)
import Firebase exposing (..)
import GroupDoc
import Html exposing (Html, text)
import Json.Encode as E
import Keyboard
import Keyboard.Extra as KX exposing (Key)
import Mat exposing (cs)
import Material
import Material.Options exposing (div)
import Menu
import Menu.Types
import Models.Todo
import Msg.AppHeader exposing (AppHeaderMsg(..))
import Msg.CustomSync exposing (CustomSyncMsg(..))
import Msg.ExclusiveMode exposing (ExclusiveModeMsg)
import Msg.Firebase exposing (..)
import Msg.GroupDoc exposing (GroupDocMsg)
import Page exposing (Page, PageMsg(..))
import Pages.EntityList
import Ports
import Ports.Firebase exposing (..)
import Ports.Todo exposing (..)
import Random.Pcg
import RouteUrl
import Set exposing (Set)
import Store
import Time exposing (Time)
import Todo.FormTypes
import Todo.Msg exposing (TodoMsg)
import Todo.Notification.Model
import Todo.Notification.Types exposing (TodoReminderOverlayModel)
import Todo.Store
import Toolkit.Operators exposing (..)
import Types.Document exposing (..)
import Types.Firebase exposing (..)
import Types.GroupDoc exposing (..)
import Types.Todo exposing (..)
import Update.AppDrawer
import Update.AppHeader
import Update.CustomSync
import Update.ExclusiveMode
import Update.Firebase
import Update.GroupDoc
import Update.Page
import Update.Subscription
import Update.Todo
import View.CustomSync
import View.Layout
import View.NewTodoFab exposing (newTodoFab)
import View.Overlays
import ViewModel
import Views.EntityList
import Window
import X.Function.Infix exposing (..)
import X.Random
import X.Record exposing (..)
import X.Return exposing (..)


type alias AppConfig =
    { debugSecondMultiplier : Float
    , deviceId : String
    , npmPackageVersion : String
    , isDevelopmentMode : Bool
    , debug : Bool
    , initialOfflineStore : E.Value
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
    | OnEntityMsgNew Pages.EntityList.Msg
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


onStartAddingTodoWithFocusInEntityAsReferenceOld : AppModel -> AppMsg
onStartAddingTodoWithFocusInEntityAsReferenceOld model =
    EntityListCursor.getMaybeEntityIdAtCursor__ model
        |> Todo.Msg.onStartAddingTodoWithFocusInEntityAsReference
        |> OnTodoMsg


revertExclusiveModeMsg =
    Msg.ExclusiveMode.OnSetExclusiveModeToNoneAndTryRevertingFocus
        |> OnExclusiveModeMsg


onSaveExclusiveModeForm : AppMsg
onSaveExclusiveModeForm =
    Msg.ExclusiveMode.OnSaveExclusiveModeForm |> OnExclusiveModeMsg


setFocusInEntityWithEntityIdMsg : EntityId -> AppMsg
setFocusInEntityWithEntityIdMsg =
    Pages.EntityList.SetFocusableEntityId >> OnEntityMsgNew


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
            [ notificationClicked Todo.Msg.OnReminderNotificationClicked

            -- note: 30 seconds is so that we can received any updates from firebase
            -- before triggering and changing any stale overdue todos timestamps.
            , everyXSeconds 30 (\_ -> Todo.Msg.OnProcessPendingNotificationCronTick)
            ]
            |> Sub.map OnTodoMsg
        , Sub.batch
            [ onFirebaseUserChanged OnFBUserChanged
            , onFCMTokenChanged OnFBFCMTokenChanged
            , onFirebaseConnectionChanged OnFBConnectionChanged
            ]
            |> Sub.map OnFirebaseMsg
        , Update.AppDrawer.subscriptions
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
    }


createAppModel : Flags -> AppModel
createAppModel flags =
    let
        { now, encodedTodoList, encodedProjectList, encodedContextList, pouchDBRemoteSyncURI } =
            flags

        storeGenerator =
            Random.Pcg.map3 (,,)
                (Todo.Store.generator flags.deviceId encodedTodoList)
                (GroupDoc.projectStoreGenerator flags.deviceId encodedProjectList)
                (GroupDoc.contextStoreGenerator flags.deviceId encodedContextList)

        ( ( todoStore, projectStore, contextStore ), seed ) =
            Random.Pcg.step storeGenerator (X.Random.seedFromTime now)

        model : AppModel
        model =
            { lastKnownCurrentTime = now
            , todoStore = todoStore
            , projectStore = projectStore
            , contextStore = contextStore
            , editMode = XMNone
            , page = Page.initialModel
            , reminderOverlay = Todo.Notification.Model.none
            , pouchDBRemoteSyncURI = pouchDBRemoteSyncURI
            , firebaseModel =
                Firebase.init flags.deviceId flags.config.initialOfflineStore
            , developmentMode = flags.developmentMode
            , selectedEntityIdSet = Set.empty
            , appVersion = flags.appVersion
            , deviceId = flags.deviceId
            , config = flags.config
            , appDrawerModel = AppDrawer.Model.initialValue flags.config.initialOfflineStore
            , mdl = Material.model
            , entityListCursor = EntityListCursor.initialValue

            --            , sequencer = sequencerInitialValue
            }
    in
    model


type alias UpdateConfig msg =
    Update.AppHeader.Config msg
        (Update.ExclusiveMode.Config msg
            (Update.Page.Config msg
                (Update.Firebase.Config msg
                    (Update.CustomSync.Config msg
                        (Update.Subscription.Config msg
                            (Update.Todo.Config msg
                                { navigateToPathMsg : List String -> msg
                                }
                            )
                        )
                    )
                )
            )
        )


updateConfig : AppModel -> UpdateConfig AppMsg
updateConfig model =
    { onStartAddingTodoToInbox = Todo.Msg.onStartAddingTodoToInbox |> OnTodoMsg
    , onStartAddingTodoWithFocusInEntityAsReference =
        onStartAddingTodoWithFocusInEntityAsReferenceOld model
    , onSetExclusiveMode = Msg.ExclusiveMode.OnSetExclusiveMode >> OnExclusiveModeMsg
    , revertExclusiveMode = revertExclusiveModeMsg
    , onSaveExclusiveModeForm = onSaveExclusiveModeForm
    , onStartSetupAddTodo = Todo.Msg.onStartSetupAddTodo |> OnTodoMsg
    , setFocusInEntityWithEntityId = setFocusInEntityWithEntityIdMsg
    , saveTodoForm = Todo.Msg.OnSaveTodoForm >> OnTodoMsg
    , saveGroupDocForm = Msg.GroupDoc.OnSaveGroupDocForm >> OnGroupDocMsg
    , focusNextEntityMsgNew = OnEntityMsgNew Pages.EntityList.ArrowDown
    , focusPrevEntityMsgNew = OnEntityMsgNew Pages.EntityList.ArrowUp
    , navigateToPathMsg = PageMsg_NavigateToPath >> OnPageMsg
    , isTodoStoreEmpty = Models.Todo.isStoreEmpty model
    }


update : UpdateConfig AppMsg -> AppMsg -> ReturnF AppMsg AppModel
update config msg =
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

        OnTodoMsg msg_ ->
            returnWithNow (OnTodoMsgWithNow msg_)

        OnTodoMsgWithNow msg_ now ->
            Update.Todo.update config now msg_

        OnFirebaseMsg msg_ ->
            let
                firebaseModel =
                    fieldLens .firebaseModel (\s b -> { b | firebaseModel = s })
            in
            overReturnF firebaseModel (Update.Firebase.update config msg_)

        OnAppDrawerMsg msg_ ->
            let
                appDrawerModel =
                    fieldLens .appDrawerModel (\s b -> { b | appDrawerModel = s })
            in
            overReturnFMapCmd appDrawerModel OnAppDrawerMsg (Update.AppDrawer.update msg_)

        _ ->
            returnWith identity (Page.getPage__ >> updatePage config msg)


updatePage config msg page =
    case ( page, msg ) of
        ( Page.EntityListPage model_, OnEntityMsgNew msg_ ) ->
            Pages.EntityList.update config msg_ model_

        ( _, OnEntityMsgNew msg_ ) ->
            Pages.EntityList.updateDefault config msg_

        _ ->
            identity


onSubscriptionMsg config msg =
    case msg of
        OnPouchDBChange dbName encodedDoc ->
            Update.Subscription.onPouchDBChange config dbName encodedDoc

        OnFirebaseDatabaseChange dbName encodedDoc ->
            effect (Update.Subscription.upsertEncodedDocOnFirebaseDatabaseChange dbName encodedDoc)


type alias ViewConfig msg =
    { noop : msg
    , onAppDrawerMsg : AppDrawer.Types.AppDrawerMsg -> msg
    , onFirebaseMsg : FirebaseMsg -> msg
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
    , onToggleAppDrawerOverlay : msg
    , onToggleDeleted : DocId -> msg
    , onToggleDeletedAndMaybeSelection : DocId -> msg
    , onToggleDoneAndMaybeSelection : DocId -> msg
    , onToggleEntitySelection : Entity.EntityId -> msg
    , onToggleGroupDocArchived : GroupDocId -> msg
    , onUpdateCustomSyncFormUri :
        ExclusiveMode.Types.SyncForm -> String -> msg
    , revertExclusiveMode : msg
    , setFocusInEntityWithEntityId : Entity.EntityId -> msg
    , updateGroupDocFromNameMsg :
        GroupDocForm -> GroupDocName -> msg
    , gotoPageMsg : Page.Page -> msg
    , maybeEntityIdAtCursorOld : Maybe EntityId
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
    , onMainMenuStateChanged = OnMainMenuStateChanged >> OnAppHeaderMsg
    , onSignIn = OnFirebaseMsg OnFBSignIn
    , onSignOut = OnFirebaseMsg OnFBSignOut
    , onFirebaseMsg = OnFirebaseMsg
    , onReminderOverlayAction = Todo.Msg.onReminderOverlayAction >> OnTodoMsg
    , onToggleAppDrawerOverlay = OnAppDrawerMsg AppDrawer.Types.OnToggleOverlay
    , onAppDrawerMsg = OnAppDrawerMsg
    , onStartAddingGroupDoc = Msg.GroupDoc.OnGroupDocAction # GDA_StartAdding >> OnGroupDocMsg
    , onUpdateCustomSyncFormUri = OnUpdateCustomSyncFormUri >>> OnCustomSyncMsg
    , onStartCustomRemotePouchSync = OnStartCustomSync >> OnCustomSyncMsg
    , gotoPageMsg = PageMsg_SetPage >> OnPageMsg
    , onMdl = OnMdl
    , onShowMainMenu = OnShowMainMenu |> OnAppHeaderMsg
    , onStartAddingTodoWithFocusInEntityAsReference =
        onStartAddingTodoWithFocusInEntityAsReferenceOld model
    , onToggleEntitySelection = Pages.EntityList.ToggleSelection >> OnEntityMsgNew
    , onStartEditingTodoProject = Todo.Msg.onStartEditingTodoProject >> OnTodoMsg
    , onStartEditingTodoContext = Todo.Msg.onStartEditingTodoContext >> OnTodoMsg
    , onStartEditingTodoText = Todo.Msg.onStartEditingTodoText >> OnTodoMsg
    , onStartEditingReminder = Todo.Msg.onStartEditingReminder >> OnTodoMsg
    , onToggleDeletedAndMaybeSelection = Todo.Msg.onToggleDeletedAndMaybeSelection >> OnTodoMsg
    , onToggleDoneAndMaybeSelection = Todo.Msg.onToggleDoneAndMaybeSelection >> OnTodoMsg
    , onToggleGroupDocArchived = Msg.GroupDoc.onToggleGroupDocArchived >> OnGroupDocMsg
    , updateGroupDocFromNameMsg =
        Msg.GroupDoc.updateGroupDocFromNameMsg >>> OnGroupDocMsg
    , onStartEditingGroupDoc = Msg.GroupDoc.onStartEditingGroupDoc >> OnGroupDocMsg
    , setFocusInEntityWithEntityId = setFocusInEntityWithEntityIdMsg
    , maybeEntityIdAtCursorOld = Nothing
    , maybeEntityIdAtCursor = Nothing
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
        Page.CustomSyncSettingsPage _ ->
            View.CustomSync.view config model
                |> frame

        Page.EntityListPage subModel ->
            Views.EntityList.view config appVM model subModel
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
                , navigateToPathMsg = PageMsg_NavigateToPath >> OnPageMsg
                }
        , init = init
        , update = update_
        , view = \model -> view (viewConfig model) model
        , subscriptions = subscriptions
        }
