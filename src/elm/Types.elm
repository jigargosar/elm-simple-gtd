module Types exposing (..)

import AppDrawer.Model
import Document.Types exposing (DocId)
import Entity.Types exposing (EntityListViewType(ContextsView), Entity)
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
import ViewType exposing (ViewType(EntityListView))
import X.Keyboard exposing (KeyboardState)
import Todo.FormTypes exposing (..)
import Msg exposing (AppMsg)
import Return


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
    , focusInEntity : Entity
    , timeTracker : Todo.TimeTracker.Model
    , config : AppConfig
    , appDrawerModel : AppDrawer.Model.Model
    , signInModel : Firebase.SignIn.Model
    , mdl : Material.Model
    , keyboardState : KeyboardState
    }


type alias AppModelF =
    AppModel -> AppModel



-- todo: IMP note if we remove appMsg dep from here. changing msg file takes 1.5mins as opposed to 36s


type alias ReturnF =
    Return.ReturnF AppMsg AppModel


type alias Return =
    Return.Return AppMsg AppModel


type alias ModelReturnF =
    AppModel -> Return


type alias ModelF =
    AppModel -> AppModel
