module Types exposing (..)

import AppDrawer.Model
import Document.Types exposing (DocId)
import Entity.Types exposing (EntityListViewType(ContextsView), Entity)
import ExclusiveMode.Types exposing (ExclusiveMode)
import Firebase.SignIn
import Firebase.Types exposing (FCMToken, FirebaseClient, FirebaseUser)
import GroupDoc.Types exposing (ContextStore, ProjectStore)
import Keyboard.Combo
import Material
import Msg exposing (AppMsg)
import Return
import Set exposing (Set)
import Time exposing (Time)
import Todo.Notification.Types exposing (TodoReminderOverlayModel)
import Todo.TimeTracker
import Todo.Types exposing (TodoStore)
import ViewType exposing (ViewType(EntityListView))
import X.Keyboard exposing (KeyboardState)
import Json.Encode as E
import LaunchBar.Models exposing (LaunchBar)
import Todo.FormTypes exposing (..)


type alias LocalPref =
    { appDrawer : AppDrawer.Model.Model
    , signIn : Firebase.SignIn.Model
    }


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


type alias AppConfig =
    { isFirstVisit : Bool
    }


type alias AppModel =
    { now : Time
    , todoStore : TodoStore
    , projectStore : ProjectStore
    , contextStore : ContextStore
    , editMode : ExclusiveMode
    , launchBar : LaunchBar
    , maybeTodoEditForm : Maybe TodoForm
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
    , keyComboModel : Keyboard.Combo.Model Msg.AppMsg
    , config : AppConfig
    , appDrawerModel : AppDrawer.Model.Model
    , signInModel : Firebase.SignIn.Model
    , mdl : Material.Model
    , keyboardState : KeyboardState
    }


type alias Return =
    Return.Return AppMsg AppModel


type alias ModelReturnF =
    AppModel -> Return


type alias ReturnF =
    Return.ReturnF AppMsg AppModel


type alias ModelF =
    AppModel -> AppModel


defaultView =
    EntityListView ContextsView


type alias Subscriptions =
    AppModel -> Sub AppMsg
