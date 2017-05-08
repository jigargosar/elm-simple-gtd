module Model.Types exposing (..)

import Context
import Document exposing (Id)
import EditMode exposing (EditMode)
import Ext.Keyboard as Keyboard
import Firebase
import ListSelection
import Project
import Project
import Random.Pcg exposing (Seed)
import ReminderOverlay
import RunningTodo exposing (RunningTodo)
import Set exposing (Set)
import Toolkit.Helpers exposing (..)
import Toolkit.Operators exposing (..)
import Ext.Function exposing (..)
import Time exposing (Time)
import Todo


type alias Selection =
    Set Todo.Id


type MainViewType
    = GroupByContextView
    | ProjectView Id
    | DoneView
    | BinView
    | GroupByProjectView
    | ContextView Id
    | SyncView


type alias Model =
    { now : Time
    , todoStore : Todo.Store
    , projectStore : Project.Store
    , contextStore : Context.Store
    , editMode : EditMode
    , mainViewType : MainViewType
    , seed : Seed
    , maybeRunningTodo : Maybe RunningTodo
    , keyboardState : Keyboard.State
    , selection : Selection
    , showDeleted : Bool
    , reminderOverlay : ReminderOverlay.Model
    , pouchDBRemoteSyncURI : String
    , appDrawerForceNarrow : Bool
    , listSelection : ListSelection.Model Document.Id
    , user : Firebase.User
    , fcmToken : Firebase.FCMToken
    , firebaseAppAttributes : Firebase.AppAttributes
    , developmentMode : Bool
    }


type ModelField
    = NowField Time
    | MainViewTypeField MainViewType


type alias ModelF =
    Model -> Model


type EntityAction
    = StartEditing
    | ToggleDeleted
    | Save
    | NameChanged String


type Entity
    = ProjectEntity Project.Model
    | ContextEntity Context.Model
    | TodoEntity Todo.Model


type GroupByEntityType
    = ProjectEntityType
    | ContextEntityType


type EntityStoreType
    = ProjectEntityStoreType
    | ContextEntityStoreType


type alias Flags =
    { now : Time
    , encodedTodoList : List Todo.Encoded
    , encodedProjectList : List Project.Encoded
    , encodedContextList : List Context.Encoded
    , pouchDBRemoteSyncURI : String
    , firebaseAppAttributes : Firebase.AppAttributes
    , developmentMode : Bool
    }


type alias TodoNotification =
    { title : String
    , tag : String
    , data : TodoNotificationData
    }


type alias TodoNotificationData =
    { id : String }


type alias TodoNotificationEvent =
    { action : String
    , data : TodoNotificationData
    }
