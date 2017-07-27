module Types exposing (AppConfig, AppModel, AppModelOtherFields)

import AppDrawer.Model
import Document exposing (DocId)
import EntityList.Types exposing (HasEntityList)
import ExclusiveMode.Types exposing (ExclusiveMode)
import Firebase.SignIn
import Firebase.Types exposing (FCMToken, FirebaseClient, FirebaseUser)
import GroupDoc.Types exposing (ContextStore, ProjectStore)
import Material
import Model.HasFocusInEntity exposing (HasFocusInEntity)
import Set exposing (Set)
import Time exposing (Time)
import Todo.Notification.Types exposing (TodoReminderOverlayModel)
import Todo.TimeTracker
import Todo.Types exposing (TodoStore)
import ViewType exposing (ViewType(EntityListView))


type alias AppConfig =
    { isFirstVisit : Bool
    }


type alias AppModel =
    HasEntityList (HasFocusInEntity AppModelOtherFields)


type alias AppModelOtherFields =
    { now : Time
    , todoStore : TodoStore
    , projectStore : ProjectStore
    , contextStore : ContextStore
    , editMode : ExclusiveMode
    , viewType : ViewType
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
