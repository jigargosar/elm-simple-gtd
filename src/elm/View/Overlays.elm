module View.Overlays exposing (overlayViews)

import AppDrawer.Model
import AppDrawer.Types
import AppDrawer.View
import Entity.View
import ExclusiveMode.Types exposing (..)
import Model.ViewType
import Todo.FormTypes exposing (..)
import Todo.GroupEditView
import View.CustomSync
import X.Html exposing (boolProperty, onClickStopPropagation)
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import View.Header
import Todo.Notification.View exposing (maybeOverlay)
import Todo.View
import LaunchBar.View
import GroupDoc.FormView
import View.GetStarted
import View.MainMenu


overlayViews config appModel =
    let
        def =
            span [] []

        editModeOverlayView =
            case appModel.editMode of
                XMLaunchBar launchBar ->
                    LaunchBar.View.init launchBar
                        |> Html.map config.onLaunchBarMsg

                XMTodoForm form ->
                    case form.mode of
                        TFM_Edit editMode ->
                            case editMode of
                                ETFM_EditTodoContext ->
                                    Todo.GroupEditView.context config form appModel

                                ETFM_EditTodoProject ->
                                    Todo.GroupEditView.project config form appModel

                                ETFM_EditTodoSchedule ->
                                    Todo.View.editTodoSchedulePopupView config form

                                ETFM_EditTodoText ->
                                    Todo.View.editTodoTextView config form

                        TFM_Add addMode ->
                            case addMode of
                                ATFM_SetupFirstTodo ->
                                    View.GetStarted.setup config form

                                ATFM_AddWithFocusInEntityAsReference ->
                                    Todo.View.new config form

                                ATFM_AddToInbox ->
                                    Todo.View.new config form

                XMSignInOverlay ->
                    View.GetStarted.signInOverlay
                        |> Html.map config.onFirebaseMsg

                XMGroupDocForm form ->
                    GroupDoc.FormView.init config form

                XMMainMenu menuState ->
                    View.MainMenu.init config menuState appModel

                _ ->
                    def
    in
        [ Just editModeOverlayView
        , Todo.Notification.View.maybeOverlay config appModel
        ]
            |> List.filterMap identity
