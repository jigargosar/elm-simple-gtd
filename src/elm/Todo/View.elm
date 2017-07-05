module Todo.View exposing (..)

import Context
import Date
import Dict
import Document
import Entity
import Material
import Material.Button
import Material.Icon
import Material.Options
import X.Html exposing (onClickStopPropagation, onMouseDownStopPropagation)
import X.Time
import Keyboard.Extra as Key exposing (Key)
import List.Extra as List
import Mat
import Model
import Model exposing (Msg, commonMsg)
import Project
import Regex
import RegexHelper
import Set
import String.Extra as String
import Time exposing (Time)
import Todo
import Todo.Form
import Todo.Msg
import Todo.NewForm
import Todo.ReminderForm
import Todo.View.Menu
import Toolkit.Operators exposing (..)
import X.Function.Infix exposing (..)
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import X.Keyboard exposing (KeyboardEvent, onEscape, onKeyDown, onKeyDownPreventDefault, onKeyDownStopPropagation, onKeyUp)
import View.Shared exposing (defaultOkCancelButtons, defaultOkCancelDeleteButtons)
import ViewModel
import WebComponents exposing (..)


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
    , canBeFocused : Bool
    , showContextDropDownMsg : Msg
    , showProjectDropDownMsg : Msg
    , reminder : ScheduleViewModel
    , onFocusIn : Msg
    , tabindexAV : Int
    , isSelected : Bool
    , onMoreMenuClicked : Msg
    , mdl : Material.Model
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


createTodoViewModel : ViewModel.Model -> Bool -> Todo.Model -> TodoViewModel
createTodoViewModel appVM canBeFocused todo =
    let
        tabindexAV =
            let
                tabindexValue =
                    if canBeFocused then
                        0
                    else
                        -1
            in
                tabindexValue

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
            Model.OnEntityMsg (Entity.Todo todo)

        onTodoMsg =
            Model.OnTodoMsg

        reminder =
            createScheduleViewModel now todo

        onKeyDownMsg ({ key } as ke) =
            if X.Keyboard.isNoSoftKeyDown ke then
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
                        reminder.startEditingMsg

                    Key.CharG ->
                        createEntityActionMsg Entity.Goto

                    Key.CharS ->
                        Todo.Msg.SwitchOrStartRunning todoId |> onTodoMsg

                    _ ->
                        commonMsg.noOp
            else
                commonMsg.noOp

        startEditingMsg =
            if canBeFocused then
                createEntityActionMsg Entity.StartEditing
            else
                Model.noop

        toggleDeleteMsg =
            createEntityActionMsg Entity.ToggleDeleted

        toggleDoneMsg =
            createEntityActionMsg Entity.ToggleArchived
    in
        { isDone = Todo.isDone todo
        , key = todoId
        , isDeleted = Todo.getDeleted todo
        , onKeyDownMsg = onKeyDownMsg
        , displayText = getDisplayText todo
        , projectDisplayName = projectDisplayName
        , contextDisplayName = contextDisplayName
        , showContextDropDownMsg = Model.StartEditingContext todo
        , showProjectDropDownMsg = Model.StartEditingProject todo
        , startEditingMsg = startEditingMsg
        , canBeFocused = canBeFocused
        , toggleDoneMsg = toggleDoneMsg
        , reminder = reminder
        , onFocusIn = createEntityActionMsg Entity.OnFocusIn
        , tabindexAV = tabindexAV
        , isSelected = appVM.selectedEntityIdSet |> Set.member todoId
        , onMoreMenuClicked = Todo.Msg.OnShowMoreMenu todoId |> onTodoMsg
        , mdl = appVM.mdl
        }


keyedItem : TodoViewModel -> ( String, Html Msg )
keyedItem vm =
    ( vm.key, item vm )


item : TodoViewModel -> Html Msg
item vm =
    div
        [ classList
            [ "todo-item focusable-list-item collection-item" => True
            , "selected" => vm.isSelected
            , "can-be-focused" => vm.canBeFocused
            ]
        , X.Html.onFocusIn vm.onFocusIn
        , tabindex vm.tabindexAV
        , onKeyDown vm.onKeyDownMsg
        , attribute "data-key" vm.key
        ]
        [ div
            [ class "display-text-container layout horizontal"
            , onMouseDown vm.startEditingMsg
            ]
            [ div [ class "self-start" ] [ doneIconButton vm ]
            , div
                [ class "display-text"
                ]
              <|
                parseDisplayText vm
            , div [ class "self-start" ] [ moreIconButton vm ]
            ]
        , div
            [ class "layout horizontal end-justified"
            ]
            [ div [ style [ "margin" => "0 8px" ] ] [ editScheduleButton vm ]
            , div [ style [ "padding" => "0 8px" ], class "layout horizontal center-center" ]
                [ a
                    [ id ("edit-context-button-" ++ vm.key)
                    , style [ "color" => "black", "min-width" => "3rem" ]
                    , onClick vm.showContextDropDownMsg
                    , tabindex vm.tabindexAV
                    ]
                    [ text vm.contextDisplayName ]
                ]
            , div [ style [ "padding" => "0 8px" ], class "layout horizontal center-center" ]
                [ a
                    [ id ("edit-project-button-" ++ vm.key)
                    , style [ "color" => "black", "min-width" => "3rem" ]
                    , onClick vm.showProjectDropDownMsg
                    , tabindex vm.tabindexAV
                    ]
                    [ text vm.projectDisplayName ]
                ]
            ]
        ]


parseDisplayText { displayText, tabindexAV } =
    --Markdown.toHtml Nothing displayText
    let
        createLink url =
            a
                [ href url
                , target "_blank"
                , onMouseDownStopPropagation Model.noop
                , tabindex tabindexAV
                ]
                [ url |> RegexHelper.stripUrlPrefix |> String.ellipsis 30 |> String.toLower |> text ]

        linkStrings =
            Regex.find Regex.All RegexHelper.url displayText
                .|> .match
                >> createLink

        nonLinkStrings =
            Regex.split Regex.All RegexHelper.url displayText
                .|> text
    in
        List.interweave nonLinkStrings linkStrings


classListAsClass list =
    list
        |> List.filter Tuple.second
        |> List.map Tuple.first
        |> String.join " "


doneIconButton : TodoViewModel -> Html Msg
doneIconButton vm =
    Mat.iconBtn4 "done"
        vm.tabindexAV
        (classListAsClass [ "done-icon" => True, "is-done" => vm.isDone ])
        vm.toggleDoneMsg


moreIconButton : TodoViewModel -> Html Msg
moreIconButton vm =
    Mat.iconBtn vm.mdl
        [ Mat.id ("todo-more-menu-button-" ++ vm.key)
        , Mat.onClickStopPropagation vm.onMoreMenuClicked
        , Mat.tabIndex vm.tabindexAV
        ]
        [ Mat.iconSmall "more_vert" ]


editScheduleButton vm =
    div
        [ id ("edit-schedule-button-" ++ vm.key)
        , class "layout horizontal center-center"
        , onClick vm.reminder.startEditingMsg
        ]
        [ div
            [ classList
                [ "overdue" => vm.reminder.isOverDue
                , "reminder-text" => True
                ]
            ]
            [ vm.reminder.displayText |> text ]
        , Mat.iconBtn vm.mdl
            [ Mat.tabIndex vm.tabindexAV
            ]
            [ Mat.iconSmall "schedule" ]
        ]


type alias ScheduleViewModel =
    { displayText : String
    , isOverDue : Bool
    , startEditingMsg : Msg
    }


createScheduleViewModel : Time -> Todo.Model -> ScheduleViewModel
createScheduleViewModel now todo =
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
                    X.Time.smartFormat now time

        displayText =
            Todo.getMaybeTime todo ?|> formatReminderTime ?= ""
    in
        { displayText = displayText
        , isOverDue = displayText == overDueText
        , startEditingMsg = Model.StartEditingReminder todo
        }


fireCancel =
    Model.OnDeactivateEditingMode


edit : Todo.Form.Model -> Model.Model -> Html Msg
edit form appModel =
    let
        todoText =
            form.todoText

        fireTextChanged =
            Todo.Form.SetText >> Model.UpdateTodoForm form

        fireToggleDelete =
            Model.OnEntityMsg form.entity Entity.ToggleDeleted
    in
        div
            [ class "overlay"
            , onClickStopPropagation fireCancel
            , onKeyDownStopPropagation (\_ -> Model.noop)
            ]
            [ div [ class "modal fixed-center", onClickStopPropagation Model.noop ]
                [ div [ class "modal-content" ]
                    [ div [ class "input-field", onKeyDownStopPropagation (\_ -> Model.noop) ]
                        [ textarea
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


new form =
    div
        [ class "overlay"
        , onClickStopPropagation fireCancel
        , onKeyDownStopPropagation (\_ -> Model.noop)
        ]
        [ div [ class "modal fixed-center", onClickStopPropagation Model.noop ]
            [ div [ class "modal-content" ]
                [ div [ class "input-field" ]
                    [ textarea
                        [ class "materialize-textarea auto-focus"
                        , onInput (Model.NewTodoTextChanged form)
                        , form |> Todo.NewForm.getText |> defaultValue
                        ]
                        []
                    , label [ class "active" ] [ text "New Todo" ]
                    ]
                , defaultOkCancelButtons
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
            , onKeyDownStopPropagation (\_ -> Model.noop)
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
