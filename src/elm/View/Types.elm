module View.Types exposing (..)

import AppDrawer.Types
import Document
import Entity.Types exposing (..)
import ExclusiveMode.Types
import Firebase.Types
import GroupDoc.Types
import LaunchBar.Messages
import Material
import Menu
import Menu.Types
import Page
import Todo.FormTypes
import Todo.Notification.Model
import Todo.Types
import X.Keyboard


type alias ViewConfig msg =
    { noop : msg
    , onEntityUpdateMsg : EntityId -> EntityUpdateAction -> msg
    , onAppDrawerMsg : AppDrawer.Types.Msg -> msg
    , onFirebaseMsg : Firebase.Types.FirebaseMsg -> msg
    , onLaunchBarMsg : LaunchBar.Messages.LaunchBarMsg -> msg
    , onMainMenuStateChanged : Menu.Types.MenuState -> msg
    , onMdl : Material.Msg msg -> msg
    , onReminderOverlayAction : Todo.Notification.Model.Action -> msg
    , onSaveExclusiveModeForm : msg
    , onSetContext : Document.DocId -> GroupDoc.Types.ContextDoc -> msg
    , onSetProject : Document.DocId -> GroupDoc.Types.ProjectDoc -> msg
    , onSetTodoFormMenuState : Todo.FormTypes.TodoForm -> Menu.State -> msg
    , onSetTodoFormReminderDate : Todo.FormTypes.TodoForm -> String -> msg
    , onSetTodoFormReminderTime : Todo.FormTypes.TodoForm -> String -> msg
    , onSetTodoFormText : Todo.FormTypes.TodoForm -> String -> msg
    , onShowMainMenu : msg
    , onSignIn : msg
    , onSignOut : msg
    , onStartAddingGroupDoc : GroupDoc.Types.GroupDocType -> msg
    , onStartAddingTodoWithFocusInEntityAsReference : msg
    , onStartCustomRemotePouchSync : ExclusiveMode.Types.SyncForm -> msg
    , onStartEditingGroupDoc : GroupDoc.Types.GroupDocId -> msg
    , onStartEditingReminder : Todo.Types.TodoDoc -> msg
    , onStartEditingTodoContext : Todo.Types.TodoDoc -> msg
    , onStartEditingTodoProject : Todo.Types.TodoDoc -> msg
    , onStartEditingTodoText : Todo.Types.TodoDoc -> msg
    , onStopRunningTodoMsg : msg
    , onSwitchOrStartTrackingTodo : Document.DocId -> msg
    , onToggleAppDrawerOverlay : msg
    , onToggleDeleted : Document.DocId -> msg
    , onToggleDeletedAndMaybeSelection : Document.DocId -> msg
    , onToggleDoneAndMaybeSelection : Document.DocId -> msg
    , onToggleEntitySelection : Entity.Types.EntityId -> msg
    , onToggleGroupDocArchived : GroupDoc.Types.GroupDocId -> msg
    , onUpdateCustomSyncFormUri :
        ExclusiveMode.Types.SyncForm -> String -> msg
    , revertExclusiveMode : msg
    , setFocusInEntityWithEntityId : Entity.Types.EntityId -> msg
    , updateGroupDocFromNameMsg :
        GroupDoc.Types.GroupDocForm -> GroupDoc.Types.GroupDocName -> msg
    , switchToEntityListViewTypeMsg : Entity.Types.EntityListPageModel -> msg
    , gotoPage : Page.Page -> msg
    }
