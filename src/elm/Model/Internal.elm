module Model.Internal exposing (..)

import Context
import Entity.Types exposing (GroupEntityType(ContextEntity), createContextEntity)
import ExclusiveMode.Types exposing (ExclusiveMode(XMNone))
import Firebase
import LocalPref
import Material
import Model.ViewType
import Project
import Random.Pcg
import Return
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
import X.Random
import Json.Encode as E
import Types exposing (..)
import Ports exposing (onFirebaseDatabaseChangeSub)
import Store
import Subscriptions.AppDrawer
import Subscriptions.Firebase
import Subscriptions.Todo
import Time
import Types exposing (AppModel)
import X.Keyboard


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
        model
