module View exposing (..)

import AppDrawer.Types
import Document
import Entity.Types
import ExclusiveMode.Types
import Firebase.Types
import GroupDoc.Types
import Html exposing (text)
import LaunchBar.Messages
import Mat exposing (..)
import Material
import Material.Button
import Material.Options exposing (div)
import Material.Tooltip
import Menu
import Menu.Types
import Todo.FormTypes
import Todo.Notification.Model
import Todo.Types
import View.Layout
import View.Overlays
import ViewModel
import ViewType
import X.Keyboard


type alias Config msg =
    { noop : msg
    , onAppDrawerMsg : AppDrawer.Types.Msg -> msg
    , onEntityListKeyDown :
        List Entity.Types.Entity -> X.Keyboard.KeyboardEvent -> msg
    , onEntityUpdateMsg :
        Entity.Types.EntityId -> Entity.Types.EntityUpdateAction -> msg
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
    , switchToEntityListViewTypeMsg : Entity.Types.EntityListViewType -> msg
    , switchToView : ViewType.ViewType -> msg
    }


init config model =
    let
        appVM =
            ViewModel.create config model

        children =
            [ View.Layout.appLayoutView config appVM model
            , newTodoFab config model
            ]
                ++ View.Overlays.overlayViews config model
    in
    div [ cs "mdl-typography--body-1" ] children


newTodoFab config m =
    div [ cs "primary-fab-container" ]
        [ div [ Material.Tooltip.attach config.onMdl [ 0 ] ]
            [ Mat.fab config.onMdl
                m.mdl
                [ id "add-fab"
                , Material.Button.colored
                , onClickStopPropagation
                    config.onStartAddingTodoWithFocusInEntityAsReference
                , resourceId "add-todo-fab"
                ]
                [ icon "add" ]
            ]
        , Material.Tooltip.render config.onMdl
            [ 0 ]
            m.mdl
            [ Material.Tooltip.left ]
            [ div [ cs "mdl-typography--body-2" ] [ text "Quick Add Task (q)" ]
            , div [ cs "mdl-typography--body-1" ] [ text "Add To Inbox (i)" ]
            ]
        ]
