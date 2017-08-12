module View.Overlays exposing (overlayViews)

import ExclusiveMode.Types exposing (..)
import GroupDoc.FormView
import Html exposing (..)
import Todo.FormTypes exposing (..)
import Todo.GroupEditView
import Todo.ReminderOverlay.View exposing (maybeOverlay)
import Todo.View
import View.GetStarted
import Views.MainMenuOverlay
import Views.SignInOverlay


overlayViews config appModel =
    let
        def =
            span [] []

        editModeOverlayView =
            case appModel.editMode of
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

                                ATFM_AddWithFocusInEntityAsReference _ ->
                                    Todo.View.new config form

                                ATFM_AddToInbox ->
                                    Todo.View.new config form

                XMSignInOverlay ->
                    Views.SignInOverlay.init config

                XMGroupDocForm form ->
                    GroupDoc.FormView.init config form

                XMMainMenu menuState ->
                    Views.MainMenuOverlay.view config menuState appModel

                XMNone ->
                    def
    in
    [ Just editModeOverlayView
    , Todo.ReminderOverlay.View.maybeOverlay config appModel
    ]
        |> List.filterMap identity
