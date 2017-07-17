port module Main exposing (main)

import AppDrawer.Main
import Context
import Entity.Types exposing (GroupEntityType(ContextEntity), createContextEntity)
import ExclusiveMode.Types exposing (ExclusiveMode(XMNone))
import Firebase
import Firebase.Main
import LocalPref
import Material
import Model.ViewType
import Project
import Random.Pcg
import Return
import RouteUrl
import Routes
import Set
import Store
import Time exposing (Time)
import Update.Todo
import Todo.Notification.Model
import Todo.Store
import Todo.TimeTracker
import Update
import View
import X.Keyboard
import Json.Encode as E
import Msg exposing (AppMsg)
import X.Random
import Json.Encode as E
import Types exposing (..)


port onFirebaseDatabaseChange : (( String, E.Value ) -> msg) -> Sub msg


onFirebaseDatabaseChangeSub tagger =
    onFirebaseDatabaseChange (uncurry tagger)


main : RouteUrl.RouteUrlProgram Flags AppModel Msg.AppMsg
main =
    RouteUrl.programWithFlags
        { delta2url = Routes.delta2hash
        , location2messages = Routes.hash2messages
        , init = init
        , update = update
        , view = View.init
        , subscriptions = subscriptions
        }


subscriptions : AppModel -> Sub Msg.AppMsg
subscriptions model =
    Sub.batch
        [ Sub.batch
            [ Time.every (Time.second * 1) Msg.OnNowChanged
            , X.Keyboard.subscription Msg.OnKeyboardMsg
            , X.Keyboard.ups Msg.OnGlobalKeyUp
            , Store.onChange Msg.OnPouchDBChange
            , onFirebaseDatabaseChangeSub Msg.OnFirebaseDatabaseChange
            ]
            |> Sub.map Msg.OnSubscriptionMsg
        , Update.Todo.subscriptions model |> Sub.map Msg.OnTodoMsg
        , Firebase.Main.subscriptions model
        , AppDrawer.Main.subscriptions model
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


init : Flags -> Return
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
            , mainViewType = Model.ViewType.defaultView
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


update : AppMsg -> AppModel -> Return
update msg =
    let
        andThenUpdate =
            update >> Return.andThen
    in
        Return.singleton
            >> Update.update andThenUpdate msg
