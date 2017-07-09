module Types exposing (..)

import AppDrawer.Model
import Document.Types exposing (DocId)
import Entity.Types exposing (EntityListViewType, EntityType)
import ExclusiveMode.Types exposing (ExclusiveMode)
import Firebase.SignIn
import Firebase.Types exposing (FCMToken, FirebaseClient, FirebaseUser)
import GroupDoc.Types exposing (ContextStore, ProjectStore)
import Keyboard.Combo
import Material
import Msg exposing (Msg)
import Set exposing (Set)
import Time exposing (Time)
import Todo.Notification.Types exposing (TodoReminderOverlayModel)
import Todo.TimeTracker
import Todo.Types exposing (TodoStore)
import ViewType exposing (ViewType)
import X.Keyboard exposing (KeyboardState)


type alias AppConfig =
    { isFirstVisit : Bool
    }


type alias AppModel =
    { now : Time
    , todoStore : TodoStore
    , projectStore : ProjectStore
    , contextStore : ContextStore
    , editMode : ExclusiveMode
    , mainViewType : ViewType
    , reminderOverlay : TodoReminderOverlayModel
    , pouchDBRemoteSyncURI : String
    , user : FirebaseUser
    , fcmToken : FCMToken
    , firebaseClient : FirebaseClient
    , developmentMode : Bool
    , selectedEntityIdSet : Set DocId
    , appVersion : String
    , deviceId : String
    , focusInEntity : EntityType
    , timeTracker : Todo.TimeTracker.Model
    , keyComboModel : Keyboard.Combo.Model Msg
    , config : AppConfig
    , appDrawerModel : AppDrawer.Model.Model
    , signInModel : Firebase.SignIn.Model
    , mdl : Material.Model
    , keyboardState : KeyboardState
    }
