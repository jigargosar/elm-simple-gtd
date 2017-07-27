module Model.Internal exposing (..)

import Context
import EntityList
import ExclusiveMode.Types exposing (ExclusiveMode(XMNone))
import Firebase
import Json.Encode as E
import LocalPref
import Material
import Model.HasFocusInEntity
import Model.ViewType
import Project
import Random.Pcg
import Set
import Time exposing (Time)
import Todo.Notification.Model
import Todo.Store
import Todo.TimeTracker
import Types exposing (..)
import X.Random


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
            , reminderOverlay = Todo.Notification.Model.none
            , pouchDBRemoteSyncURI = pouchDBRemoteSyncURI
            , user = firebaseModel.user
            , fcmToken = firebaseModel.fcmToken
            , firebaseClient = firebaseModel.firebaseClient
            , developmentMode = flags.developmentMode
            , selectedEntityIdSet = Set.empty
            , appVersion = flags.appVersion
            , deviceId = flags.deviceId
            , focusInEntity_ = Model.HasFocusInEntity.init
            , timeTracker = Todo.TimeTracker.none
            , config = flags.config
            , appDrawerModel = localPref.appDrawer
            , signInModel = localPref.signIn
            , mdl = Material.model
            , entityList = EntityList.initialValue
            }
    in
    model
