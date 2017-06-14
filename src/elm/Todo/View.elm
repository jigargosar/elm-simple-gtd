module Todo.View exposing (..)

import Context
import Date
import Date.Distance exposing (inWords)
import Dict
import Document
import Dom
import ExclusiveMode
import Entity
import Ext.Decode exposing (traceDecoder)
import Ext.Time
import Html.Attributes.Extra exposing (intProperty)
import Html.Events.Extra exposing (onClickPreventDefaultAndStopPropagation, onClickStopPropagation)
import Html.Keyed
import Json.Decode
import Json.Encode
import Keyboard.Extra as Key exposing (Key)
import List.Extra as List
import Material
import Maybe.Extra as Maybe
import Menu
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
import Todo.Msg
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
import View.FullBleedCapture
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

                    Key.CharR ->
                        Model.StartEditingReminder todo

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
        [ div [ style [ "margin" => "0 8px" ] ] [ editScheduleButton vm ]
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
        [ id ("edit-context-button-" ++ vm.key)
        , style [ "height" => "24px" ]
        , class "small padding-0 margin-0 shrink"
        , vm.tabindexAV
        , onClick vm.showContextDropdownMsg
        ]
        [ div [ class "title primary-text-color" ] [ text vm.contextDisplayName ]
        ]


projectProjectButton vm =
    Paper.button
        [ id ("edit-project-button-" ++ vm.key)
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
        div
            [ id ("edit-schedule-button-" ++ vm.key)
            , class "layout horizontal center-center"
            , onClick reminderVM.startEditingMsg
            ]
            [ div
                [ classList
                    [ "overdue" => reminderVM.isOverDue
                    , "reminder-text" => True
                    ]
                ]
                [ reminderVM.displayText |> text ]
            , Material.smallIconButton "schedule"
                [ vm.tabindexAV
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
            Todo.Msg.UpdateReminderForm form >> Model.OnTodoMsg

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


reminderPopup form model =
    {- Menu.view ([ "i1", "i2", "aa" , "Pick date and time"])
       form.menuState
       (createReminderMenuConfig form model)
    -}
    let
        updateReminderForm =
            Todo.Msg.UpdateReminderForm form >> Model.OnTodoMsg
    in
        div
            [ class "fullbleed-capture"
            , onClickStopPropagation Model.OnDeactivateEditingMode
            ]
            [ div
                [ id "popup-menu"
                , class "z-depth-4 static"
                , onClickStopPropagation commonMsg.noOp
                ]
                [ div [ class "font-subhead" ] [ text "Select date and time" ]
                , div [ class "input-field" ]
                    [ Html.input
                        [ type_ "date"
                        , class "auto-focus"
                        , value form.date
                        , Todo.ReminderForm.SetDate >> updateReminderForm |> onChange
                        ]
                        []
                    , Html.label [ class "active" ] [ "Date" |> text ]
                    ]
                , div [ class "input-field" ]
                    [ Html.input
                        [ type_ "time"
                        , value form.time
                        , Todo.ReminderForm.SetTime >> updateReminderForm |> onChange
                        ]
                        []
                    , Html.label [ class "active" ] [ "Time" |> text ]
                    ]
                , defaultOkCancelButtons
                ]
            ]


createReminderMenuConfig : Todo.ReminderForm.Model -> Model.Model -> Menu.Config String Model.Msg
createReminderMenuConfig form model =
    { onSelect = (\_ -> commonMsg.noOp)
    , isSelected = (\_ -> False)
    , itemKey = identity
    , itemSearchText = identity
    , itemView = text
    , onStateChanged =
        Todo.ReminderForm.SetMenuState
            >> Todo.Msg.UpdateReminderForm form
            >> Model.OnTodoMsg
    , noOp = commonMsg.noOp
    , onOutsideMouseDown = Model.OnDeactivateEditingMode
    }
