module Types.AppModel exposing (AppConfig, AppModel, AppModelOtherFields)

import AppDrawer.Model
import EntityListCursor exposing (HasEntityListCursor)
import ExclusiveMode.Types exposing (ExclusiveMode)
import Firebase.SignIn
import Material
import Page exposing (Page(EntityListPage))
import Set exposing (Set)
import Time exposing (Time)
import Todo.Notification.Types exposing (TodoReminderOverlayModel)
import Todo.TimeTracker
import Types.Document exposing (..)
import Types.Firebase exposing (..)
import Types.GroupDoc exposing (..)
import Types.Todo exposing (..)


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
    , user : FirebaseUser
    , fcmToken : FCMToken
    , firebaseClient : FirebaseClient
    , developmentMode : Bool
    , selectedEntityIdSet : Set DocId
    , appVersion : String
    , deviceId : String
    , timeTracker : Todo.TimeTracker.Model
    , config : AppConfig
    , appDrawerModel : AppDrawer.Model.AppDrawerModel
    , signInModel : Firebase.SignIn.Model
    , mdl : Material.Model
    }
