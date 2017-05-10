module Types exposing (..)

import Context
import Document exposing (Id)
import EditMode exposing (EditForm)
import Ext.Keyboard as Keyboard
import Firebase
import Project
import Project
import Random.Pcg exposing (Seed)
import ReminderOverlay
import Set exposing (Set)
import Toolkit.Helpers exposing (..)
import Toolkit.Operators exposing (..)
import Ext.Function exposing (..)
import Time exposing (Time)
import Todo


type EntityListViewType
    = GroupByContextView
    | ContextView Id
    | GroupByProjectView
    | ProjectView Id


type MainViewType
    = EntityListView EntityListViewType
    | DoneView
    | BinView
    | SyncView


type alias Model =
    { now : Time
    , todoStore : Todo.Store
    , projectStore : Project.Store
    , contextStore : Context.Store
    , editMode : EditForm
    , mainViewType : MainViewType
    , keyboardState : Keyboard.State
    , showDeleted : Bool
    , reminderOverlay : ReminderOverlay.Model
    , pouchDBRemoteSyncURI : String
    , appDrawerForceNarrow : Bool
    , user : Firebase.User
    , fcmToken : Firebase.FCMToken
    , firebaseAppAttributes : Firebase.AppAttributes
    , developmentMode : Bool
    , focusedEntityInfo : FocusedEntityInfo
    , selectedEntityIdSet : Set Document.Id
    , layout : Layout
    }


type alias Layout =
    { narrow : Bool
    }


type alias FocusedEntityInfo =
    { id : Document.Id }


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


type GroupByEntity
    = GroupByProject
    | GroupByContext


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
