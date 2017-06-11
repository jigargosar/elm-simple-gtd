module Todo.View exposing (..)

import Context
import Date
import Date.Distance exposing (inWords)
import Dict
import Document
import Dom
import EditMode
import Entity
import Ext.Decode exposing (traceDecoder)
import Ext.Time
import Html.Attributes.Extra exposing (intProperty)
import Html.Events.Extra exposing (onClickPreventDefaultAndStopPropagation, onClickStopPropagation)
import Json.Decode
import Json.Encode
import Keyboard.Extra as Key exposing (Key)
import List.Extra as List
import Material
import Maybe.Extra as Maybe
import Model
import Model exposing (Msg, commonMsg)
import Polymer.Attributes exposing (boolProperty, stringProperty)
import Polymer.Events exposing (onTap)
import Project
import Regex
import RegexBuilder
import RegexBuilder.Extra as RegexBuilder
import Set
import String.Extra as String
import Svg.Events exposing (onFocusIn, onFocusOut)
import Time.Format
import Todo
import Todo.Form
import Todo.ReminderForm
import Todo.View.Menu
import Toolkit.Helpers exposing (..)
import Toolkit.Operators exposing (..)
import Ext.Function exposing (..)
import Ext.Function.Infix exposing (..)
import Html exposing (Attribute, Html, div, h1, h3, span, text)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Ext.Keyboard exposing (KeyboardEvent, onEscape, onKeyDown, onKeyDownPreventDefault, onKeyDownStopPropagation, onKeyUp)
import Polymer.Paper as Paper
import View.Shared exposing (SharedViewModel, defaultOkCancelButtons, defaultOkCancelDeleteButtons, hideOnHover)
import WebComponents exposing (..)


initKeyed : TodoViewModel -> ( String, Html Msg )
initKeyed vm =
    ( vm.key, init vm )


init : TodoViewModel -> Html Msg
init vm =
    div
        [ classList [ "todo-item" => True, "selected" => vm.isSelected, "editing" => vm.isEditing ]
        , onFocusIn vm.onFocusIn
        , vm.tabindexAV
        , onKeyDown vm.onKeyDownMsg
        , attribute "data-key" vm.key
        ]
        (vm.edit |> Maybe.unpack (\_ -> defaultView vm) editView)


dropdownTrigger { tabindexAV } content =
    Paper.button
        [ style [ "height" => "24px" ]
        , slotDropdownTrigger
        , class "small padding-0 margin-0 shrink"
        , tabindexAV
        ]
        [ div [ class "title primary-text-color" ] [ content ]
        ]


type alias TodoViewModel =
    { key : String
    , displayText : String
    , isDone : Bool
    , isDeleted : Bool
    , onKeyDownMsg : KeyboardEvent -> Msg
    , projectDisplayName : String
    , contextDisplayName : String
    , setContextMsg : Context.Model -> Msg
    , setProjectMsg : Project.Model -> Msg
    , startEditingMsg : Msg
    , toggleDoneMsg : Msg
    , onDeleteClicked : Msg
    , showContextDropdownMsg : Msg
    , showProjectDropdownMsg : Msg
    , reminder : ReminderViewModel
    , edit : Maybe EditViewModel
    , isEditing : Bool
    , onFocusIn : Msg
    , tabindexAV : Attribute Msg
    , isSelected : Bool
    }


getDisplayText todo =
    let
        tripleNewLineAndRestRegex =
            (Regex.regex "\\n\\n\\n(.|\n)*")

        trimAndReplaceEmptyWithDefault =
            String.trim >> String.nonEmpty >>?= "< empty >"
    in
        Todo.getText todo
            |> trimAndReplaceEmptyWithDefault
            |> Regex.replace
                (Regex.AtMost 1)
                tripleNewLineAndRestRegex
                (\match -> "\n...")


createTodoViewModel : SharedViewModel -> Attribute Msg -> Todo.Model -> TodoViewModel
createTodoViewModel vc tabindexAV todo =
    let
        todoId =
            Document.getId todo

        truncateName =
            String.ellipsis 15

        projectId =
            Todo.getProjectId todo

        projectDisplayName =
            projectId
                |> (Dict.get # vc.projectByIdDict >>? Project.getName)
                ?= ""
                |> truncateName
                |> String.append "#"

        contextId =
            Todo.getContextId todo

        contextDisplayName =
            contextId
                |> (Dict.get # vc.contextByIdDict >>? Context.getName)
                ?= "Inbox"
                |> String.append "@"
                |> truncateName

        createEntityActionMsg =
            Model.OnEntityAction (Entity.TodoEntity todo)

        maybeEditTodoForm =
            vc.getMaybeEditTodoFormForTodo todo

        onKeyDownMsg ({ key } as ke) =
            if Ext.Keyboard.isNoSoftKeyDown ke then
                case key of
                    Key.Space ->
                        createEntityActionMsg Entity.ToggleSelected

                    Key.CharE ->
                        startEditingMsg

                    Key.CharD ->
                        toggleDoneMsg

                    Key.Delete ->
                        toggleDeleteMsg

                    Key.CharP ->
                        Model.StartEditingProject todo

                    Key.CharC ->
                        Model.StartEditingContext todo

                    Key.CharG ->
                        createEntityActionMsg Entity.Goto

                    Key.CharS ->
                        Model.onTodoInitRunning todoId

                    _ ->
                        commonMsg.noOp
            else
                commonMsg.noOp

        startEditingMsg =
            createEntityActionMsg Entity.StartEditing

        toggleDeleteMsg =
            createEntityActionMsg Entity.ToggleDeleted

        toggleDoneMsg =
            Model.ToggleTodoDone todoId

        maybeEditVM =
            maybeEditTodoForm ?|> createEditTodoViewModel # todo
    in
        { isDone = Todo.isDone todo
        , key = todoId
        , isDeleted = Todo.getDeleted todo
        , onKeyDownMsg = onKeyDownMsg
        , displayText = getDisplayText todo
        , projectDisplayName = projectDisplayName
        , contextDisplayName = contextDisplayName
        , setContextMsg = Model.SetTodoContext # todo
        , setProjectMsg = Model.SetTodoProject # todo
        , showContextDropdownMsg = Model.StartEditingContext todo
        , showProjectDropdownMsg = Model.StartEditingProject todo
        , startEditingMsg = startEditingMsg
        , toggleDoneMsg = toggleDoneMsg
        , reminder = createReminderViewModel vc todo
        , edit = maybeEditVM
        , isEditing = Maybe.isJust maybeEditVM
        , onDeleteClicked = toggleDeleteMsg
        , onFocusIn = createEntityActionMsg Entity.OnFocusIn
        , tabindexAV = tabindexAV
        , isSelected = vc.selectedEntityIdSet |> Set.member todoId
        }


defaultView : TodoViewModel -> List (Html Msg)
defaultView vm =
    [ div
        [ class ""
        , onClick vm.startEditingMsg
        ]
        [ doneIconButton vm
        , span [ class "display-text" ] [ text vm.displayText ]
        ]
    , div
        [ class "layout horizontal end-justified"
        ]
        [ reminderView vm
        , div [ style [ "margin" => "0 8px" ] ] [ editScheduleButton vm ]
        , div [ style [ "padding" => "0 8px" ] ] [ editContextButton vm ]
        , div [ style [ "padding" => "0 8px" ] ] [ projectProjectButton vm ]
        ]
    ]


doneIconButton : TodoViewModel -> Html Msg
doneIconButton vm =
    Paper.iconButton
        [ class ("done-icon done-" ++ toString (vm.isDone))
        , onClickStopPropagation (vm.toggleDoneMsg)
        , iconA "done"
        , vm.tabindexAV
        ]
        []


editContextButton vm =
    Paper.button
        [ id ("edit-context-buton-" ++ vm.key)
        , style [ "height" => "24px" ]
        , class "small padding-0 margin-0 shrink"
        , vm.tabindexAV
        , onClick vm.showContextDropdownMsg
        ]
        [ div [ class "title primary-text-color" ] [ text vm.contextDisplayName ]
        ]


projectProjectButton vm =
    Paper.button
        [ id ("edit-project-buton-" ++ vm.key)
        , style [ "height" => "24px" ]
        , class "small padding-0 margin-0 shrink"
        , vm.tabindexAV
        , onClick vm.showProjectDropdownMsg
        ]
        [ div [ class "title primary-text-color" ] [ text vm.projectDisplayName ]
        ]


editScheduleButton vm =
    let
        reminderVM =
            vm.reminder
    in
        div [ class "layout horizontal center-center", onClick reminderVM.startEditingMsg ]
            [ div
                [ classList
                    [ "overdue" => reminderVM.isOverDue
                    , "reminder-text" => True
                    ]
                ]
                [ reminderVM.displayText |> text ]
            , Material.smallIconButton "schedule"
                [ id ("edit-schedule-buton-" ++ vm.key)
                , vm.tabindexAV
                ]
            ]


type alias ReminderViewModel =
    { isDropdownOpen : Bool
    , date : String
    , time : String
    , displayText : String
    , isOverDue : Bool
    , isSnoozed : Bool
    , dueAtToolTipText : String
    , dayDiffInWords : String
    , onDateChanged : String -> Msg
    , onTimeChanged : String -> Msg
    , startEditingMsg : Msg
    }


createReminderViewModel : SharedViewModel -> Todo.Model -> ReminderViewModel
createReminderViewModel vc todo =
    let
        maybeTodoReminderForm =
            vc.getMaybeTodoReminderFormForTodo todo

        form =
            maybeTodoReminderForm
                |> Maybe.unpack (\_ -> Todo.ReminderForm.create todo vc.now) identity

        updateReminderForm =
            Model.UpdateReminderForm form

        isDropdownOpen =
            Maybe.isJust maybeTodoReminderForm

        overDueText =
            "Overdue"

        formatReminderTime time =
            let
                due =
                    Date.fromTime time

                now =
                    Date.fromTime vc.now
            in
                if time < vc.now then
                    overDueText
                else
                    Ext.Time.smartFormat vc.now time

        smartFormat =
            Ext.Time.smartFormat vc.now

        displayText =
            Todo.getMaybeTime todo ?|> formatReminderTime ?= ""

        dueAt =
            Todo.getMaybeDueAt todo
    in
        { isDropdownOpen = isDropdownOpen
        , date = form.date
        , time = form.time
        , displayText = displayText
        , isOverDue = displayText == overDueText
        , isSnoozed = Todo.isSnoozed todo
        , dueAtToolTipText = Todo.getMaybeDueAt todo ?|> Ext.Time.formatDateTime ?= ""
        , dayDiffInWords = dueAt ?|> Ext.Time.dayDiffInWords vc.now ?= ""
        , onDateChanged = updateReminderForm << Todo.ReminderForm.SetDate
        , onTimeChanged = updateReminderForm << Todo.ReminderForm.SetTime
        , startEditingMsg = Model.StartEditingReminder todo
        }


reminderView : TodoViewModel -> Html Msg
reminderView vm =
    let
        reminderVM =
            vm.reminder

        reminderTrigger =
            if reminderVM.displayText == "" then
                iconButton "alarm-add" [ vm.tabindexAV, slotDropdownTrigger, onClick reminderVM.startEditingMsg ]
            else
                dropdownTrigger vm
                    (div
                        [ onClick reminderVM.startEditingMsg
                        , classList
                            [ "reminder-text" => True
                            , "overdue" => reminderVM.isOverDue
                            ]
                        ]
                        [ icon "av:snooze" [ classList [ "display-none" => not reminderVM.isSnoozed ] ]
                        , text reminderVM.displayText
                        ]
                    )

        menuButton =
            Paper.menuButton
                [ boolProperty "opened" reminderVM.isDropdownOpen
                , boolProperty "dynamicAlign" True
                , boolProperty "stopKeyboardEventPropagation" True
                ]
                [ reminderTrigger
                , div
                    [ class "static"
                    , attribute "slot" "dropdown-content"
                    ]
                    [ div [ class "font-subhead" ] [ text "Select date and time" ]
                    , Paper.input
                        [ type_ "date"
                        , classList [ "auto-focus" => reminderVM.isDropdownOpen ]
                        , labelA "Date"
                        , value reminderVM.date
                        , boolProperty "stopKeyboardEventPropagation" True
                        , onChange reminderVM.onDateChanged
                        ]
                        []
                    , Paper.input
                        [ type_ "time"
                        , labelA "Time"
                        , value reminderVM.time
                        , boolProperty "stopKeyboardEventPropagation" True
                        , onChange reminderVM.onTimeChanged
                        ]
                        []
                    , defaultOkCancelButtons
                    ]
                ]

        timeToolTip =
            Paper.tooltip [ intProperty "offset" 0 ]
                (if reminderVM.dueAtToolTipText /= "" then
                    [ div [ class "tooltip" ]
                        [ div [ class "font-body1 font-nowrap" ] [ text reminderVM.dueAtToolTipText ]
                        , div [ class "font-caption" ] [ text reminderVM.dayDiffInWords ]
                        ]
                    ]
                 else
                    []
                )
    in
        div [ style [ "position" => "relative" ] ]
            [ menuButton, timeToolTip ]


type alias EditViewModel =
    { todo : { text : Todo.Text }
    , onTodoTextChanged : String -> Msg
    , onDeleteClicked : Msg
    }


createEditTodoViewModel : Todo.Form.Model -> Todo.Model -> EditViewModel
createEditTodoViewModel form todo =
    let
        todoId =
            form.id

        updateTodoFormMsg =
            Model.UpdateTodoForm form
    in
        { todo =
            { text = form.todoText
            }
        , onTodoTextChanged = updateTodoFormMsg << Todo.Form.SetText
        , onDeleteClicked = Model.OnEntityAction (Entity.TodoEntity todo) Entity.ToggleDeleted
        }


editView : EditViewModel -> List (Html Msg)
editView edit =
    [ div [ class "vertical layout flex-auto" ]
        [ div [ class "flex" ]
            [ div [ class "input-field", onKeyDownStopPropagation (\_ -> commonMsg.noOp) ]
                [ Html.textarea
                    [ class "materialize-textarea auto-focus"
                    , defaultValue (edit.todo.text)
                    , onInput edit.onTodoTextChanged
                    ]
                    []
                , Html.label [] [ text "Todo" ]
                ]
            ]
        , defaultOkCancelDeleteButtons edit.onDeleteClicked
        ]
    ]


projectMenu =
    Todo.View.Menu.project


contextMenu =
    Todo.View.Menu.context
