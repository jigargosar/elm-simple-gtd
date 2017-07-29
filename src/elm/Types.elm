module Types exposing (AppConfig, AppModel, AppModelOtherFields)

import AppDrawer.Model
import Document exposing (DocId)
import EntityListCursor exposing (HasEntityListCursor)
import ExclusiveMode.Types exposing (ExclusiveMode)
import Firebase.SignIn
import Firebase.Types exposing (FCMToken, FirebaseClient, FirebaseUser)
import GroupDoc.Types exposing (ContextStore, ProjectStore)
import Material
import Set exposing (Set)
import Time exposing (Time)
import Todo.Notification.Types exposing (TodoReminderOverlayModel)
import Todo.TimeTracker
import Todo.Types exposing (TodoStore)
import ViewType exposing (Page(EntityListPage))


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
    , viewType : Page
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
    , appDrawerModel : AppDrawer.Model.Model
    , signInModel : Firebase.SignIn.Model
    , mdl : Material.Model
    }



--type alias HasFocusInEntity a =
--    { a | focusInEntity : Entity }
--
--
--type alias HasFocusInEntityF a =
--    HasFocusInEntity a -> HasFocusInEntity a
--
--
--type alias HasTodoStore a =
--    { a | todoStore : TodoStore }
--
--
--type alias HasTodoStoreF a =
--    HasTodoStore a -> HasTodoStore a
