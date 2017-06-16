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
import Time exposing (Time)
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
import View.Shared exposing (defaultOkCancelButtons, defaultOkCancelDeleteButtons, hideOnHover)
import ViewModel
import WebComponents exposing (..)


initKeyed : TodoViewModel -> ( String, Html Msg )
initKeyed vm =
    ( vm.key, init vm )


init : TodoViewModel -> Html Msg
init vm =
    div
        [ classList
            [ "todo-item focusable-list-item collection-item" => True
            , "selected" => vm.isSelected
            ]
        , onFocusIn vm.onFocusIn
        , vm.tabindexAV
        , onKeyDown vm.onKeyDownMsg
        , attribute "data-key" vm.key
        ]
        (defaultView vm)


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
    , startEditingMsg : Msg
    , toggleDoneMsg : Msg
    , showContextDropdownMsg : Msg
    , showProjectDropdownMsg : Msg
    , reminder : ReminderViewModel
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


createTodoViewModel : ViewModel.Model -> Attribute Msg -> Todo.Model -> TodoViewModel
createTodoViewModel appVM tabindexAV todo =
    let
        now =
            appVM.now

        todoId =
            Document.getId todo

        truncateName =
            String.ellipsis 15

        projectId =
            Todo.getProjectId todo

        projectDisplayName =
            projectId
                |> (Dict.get # appVM.projectByIdDict >>? Project.getName)
                ?= ""
                |> truncateName
                |> String.append "#"

        contextId =
            Todo.getContextId todo

        contextDisplayName =
            contextId
                |> (Dict.get # appVM.contextByIdDict >>? Context.getName)
                ?= "Inbox"
                |> String.append "@"
                |> truncateName

        createEntityActionMsg =
            Model.OnEntityAction (Entity.TodoEntity todo)

        onTodoMsg =
            Model.OnTodoMsg

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
                        Todo.Msg.SwitchOrStartRunning todoId |> onTodoMsg

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
    in
        { isDone = Todo.isDone todo
        , key = todoId
        , isDeleted = Todo.getDeleted todo
        , onKeyDownMsg = onKeyDownMsg
        , displayText = getDisplayText todo
        , projectDisplayName = projectDisplayName
        , contextDisplayName = contextDisplayName
        , showContextDropdownMsg = Model.StartEditingContext todo
        , showProjectDropdownMsg = Model.StartEditingProject todo
        , startEditingMsg = startEditingMsg
        , toggleDoneMsg = toggleDoneMsg
        , reminder = createReminderViewModel now todo
        , onFocusIn = createEntityActionMsg Entity.OnFocusIn
        , tabindexAV = tabindexAV
        , isSelected = appVM.selectedEntityIdSet |> Set.member todoId
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
    { displayText : String
    , isOverDue : Bool
    , startEditingMsg : Msg
    }


createReminderViewModel : Time -> Todo.Model -> ReminderViewModel
createReminderViewModel now todo =
    let
        overDueText =
            "Overdue"

        formatReminderTime time =
            let
                dueDate =
                    Date.fromTime time

                nowDate =
                    Date.fromTime now
            in
                if time < now then
                    overDueText
                else
                    Ext.Time.smartFormat now time

        displayText =
            Todo.getMaybeTime todo ?|> formatReminderTime ?= ""
    in
        { displayText = displayText
        , isOverDue = displayText == overDueText
        , startEditingMsg = Model.StartEditingReminder todo
        }


edit : Todo.Form.Model -> Model.Model -> Html Msg
edit form appModel =
    let
        todoText =
            form.todoText

        fireTextChanged =
            Todo.Form.SetText >> Model.UpdateTodoForm form

        fireToggleDelete =
            Model.OnEntityAction form.entity Entity.ToggleDeleted

        fireCancel =
            Model.OnDeactivateEditingMode
    in
        div
            [ class "overlay"
            , onClickStopPropagation Model.OnDeactivateEditingMode
            ]
            [ div [ class "modal fixed-center", onClickStopPropagation fireCancel ]
                [ div [ class "modal-content" ]
                    [ div [ class "input-field", onKeyDownStopPropagation (\_ -> Model.NOOP) ]
                        [ Html.textarea
                            [ class "materialize-textarea auto-focus"
                            , defaultValue todoText
                            , onInput fireTextChanged
                            ]
                            []
                        , Html.label [] [ text "Todo" ]
                        ]
                    , defaultOkCancelDeleteButtons fireToggleDelete
                    ]
                ]
            ]


projectMenu =
    Todo.View.Menu.project


contextMenu =
    Todo.View.Menu.context


reminderPopup form =
    let
        updateReminderForm =
            Todo.Msg.UpdateReminderForm form >> Model.OnTodoMsg
    in
        div
            [ class "overlay"
            , onClickStopPropagation Model.OnDeactivateEditingMode
            , onKeyDownStopPropagation (\_ -> Model.NOOP)
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
