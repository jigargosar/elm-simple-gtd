module Main exposing (main)

import AppDrawer.Types exposing (AppDrawerMsg(..))
import CommonMsg
import Context
import EntityListCursor
import ExclusiveMode.Types exposing (..)
import Firebase
import Json.Encode as E
import Keyboard
import LaunchBar.Messages
import LocalPref
import Material
import Msg exposing (..)
import Msg.Firebase exposing (..)
import Msg.Subscription exposing (..)
import Page
import Ports
import Ports.Firebase exposing (..)
import Ports.Todo exposing (..)
import Project
import Random.Pcg
import RouteUrl
import Routes
import Set
import Time exposing (Time)
import Todo.Msg exposing (..)
import Todo.Notification.Model
import Todo.Store
import Todo.TimeTracker
import Types.AppModel exposing (..)
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
import View
import View.Config
import Window
import X.Random
import X.Return exposing (..)


subscriptions model =
    Sub.batch
        [ Sub.batch
            [ Time.every (Time.second * 1 * model.config.debugSecondMultiplier) Msg.Subscription.OnNowChanged
            , Keyboard.ups Msg.Subscription.OnGlobalKeyUp
            , Keyboard.downs Msg.Subscription.OnGlobalKeyDown
            , Ports.pouchDBChanges (uncurry Msg.Subscription.OnPouchDBChange)
            , Ports.onFirebaseDatabaseChange (uncurry Msg.Subscription.OnFirebaseDatabaseChange)
            ]
            |> Sub.map Msg.OnSubscriptionMsg
        , Sub.batch
            [ notificationClicked OnReminderNotificationClicked
            , onRunningTodoNotificationClicked RunningNotificationResponse
            , Time.every (Time.second * 1 * model.config.debugSecondMultiplier) (\_ -> UpdateTimeTracker)
            , Time.every (Time.second * 30 * model.config.debugSecondMultiplier) (\_ -> OnProcessPendingNotificationCronTick)
            ]
            |> Sub.map Msg.OnTodoMsg
        , Sub.batch
            [ onFirebaseUserChanged OnFBUserChanged
            , onFCMTokenChanged OnFBFCMTokenChanged
            , onFirebaseConnectionChanged OnFBConnectionChanged
            ]
            |> Sub.map Msg.OnFirebaseMsg
        , Sub.batch
            [ Window.resizes (\_ -> OnWindowResizeTurnOverlayOff) ]
            |> Sub.map Msg.OnAppDrawerMsg
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
            }
    in
    model


type alias UpdateConfig msg =
    Update.LaunchBar.Config msg
        (Update.AppHeader.Config msg
            (Update.ExclusiveMode.Config msg
                (Update.Page.Config msg
                    (Update.Firebase.Config msg
                        (Update.CustomSync.Config msg
                            (Update.Entity.Config msg
                                (Update.Subscription.Config msg
                                    (Update.Todo.Config msg
                                        { onTodoMsgWithNow : TodoMsg -> Time -> msg
                                        , onLaunchBarMsgWithNow : LaunchBar.Messages.LaunchBarMsg -> Time -> msg
                                        , onMdl : Material.Msg msg -> msg
                                        }
                                    )
                                )
                            )
                        )
                    )
                )
            )
        )


update : UpdateConfig AppMsg -> AppMsg -> ReturnF AppMsg AppModel
update config msg =
    let
        onPersistLocalPref =
            effect (LocalPref.encodeLocalPref >> Ports.persistLocalPref)
    in
    case msg of
        OnMdl msg_ ->
            andThen (Material.update config.onMdl msg_)

        OnPageMsg msg_ ->
            Update.Page.update config msg_

        OnCommonMsg msg_ ->
            CommonMsg.update msg_

        OnSubscriptionMsg msg_ ->
            Update.Subscription.update config msg_

        OnGroupDocMsg msg_ ->
            Update.GroupDoc.update config msg_
                >> returnMsgAsCmd Msg.updateEntityListCursorMsg

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
            returnWithNow (config.onLaunchBarMsgWithNow msg_)

        OnTodoMsg msg_ ->
            returnWithNow (config.onTodoMsgWithNow msg_)

        OnTodoMsgWithNow msg_ now ->
            Update.Todo.update config now msg_
                >> returnMsgAsCmd Msg.updateEntityListCursorMsg

        OnFirebaseMsg msg_ ->
            Update.Firebase.update config msg_
                >> onPersistLocalPref

        OnAppDrawerMsg msg ->
            Update.AppDrawer.update msg
                >> onPersistLocalPref


updateConfig : AppModel -> UpdateConfig AppMsg
updateConfig model =
    { noop = Msg.noop
    , onStartAddingTodoToInbox = Todo.Msg.onStartAddingTodoToInbox |> Msg.OnTodoMsg
    , onStartAddingTodoWithFocusInEntityAsReference =
        Todo.Msg.onStartAddingTodoWithFocusInEntityAsReference |> Msg.OnTodoMsg
    , openLaunchBarMsg = Msg.openLaunchBarMsg
    , afterTodoUpsert = Todo.Msg.afterTodoUpsert >> Msg.OnTodoMsg
    , onSetExclusiveMode = Msg.onSetExclusiveMode
    , revertExclusiveMode = Msg.revertExclusiveMode
    , switchToEntityListPageMsg = Msg.switchToEntityListPageMsg
    , setDomFocusToFocusInEntityCmd = Msg.setDomFocusToFocusInEntityCmd
    , onStartEditingTodo = Todo.Msg.onStartEditingTodo >> Msg.OnTodoMsg
    , onSaveExclusiveModeForm = Msg.onSaveExclusiveModeForm
    , onStartSetupAddTodo = Todo.Msg.onStartSetupAddTodo |> Msg.OnTodoMsg
    , setFocusInEntityWithEntityId = Msg.setFocusInEntityWithEntityIdMsg
    , saveTodoForm = Msg.onSaveTodoForm
    , saveGroupDocForm = Msg.onSaveGroupDocForm
    , onTodoMsgWithNow = Msg.OnTodoMsgWithNow
    , onLaunchBarMsgWithNow = Msg.OnLaunchBarMsgWithNow
    , onMdl = Msg.OnMdl
    , bringEntityIdInViewMsg = Msg.bringEntityIdInViewMsg
    , onGotoRunningTodoMsg = Todo.Msg.onGotoRunningTodoMsg |> Msg.OnTodoMsg
    , entityListFocusPreviousEntityMsg = Msg.entityListFocusPreviousEntityMsg
    , entityListFocusNextEntityMsg = Msg.entityListFocusNextEntityMsg
    }


main : RouteUrl.RouteUrlProgram Flags AppModel AppMsg
main =
    let
        init =
            createAppModel
                >> update_ Msg.onSwitchToNewUserSetupModeIfNeeded

        update_ : AppMsg -> AppModel -> ( AppModel, Cmd AppMsg )
        update_ msg model =
            model |> pure >> update (updateConfig model) msg
    in
    RouteUrl.programWithFlags
        { delta2url = Routes.delta2hash
        , location2messages = Routes.hash2messages View.Config.viewConfig
        , init = init
        , update = update_
        , view = View.init View.Config.viewConfig
        , subscriptions = subscriptions
        }
