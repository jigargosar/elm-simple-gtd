module Todo.View exposing (..)

import Context
import Date
import Date.Distance exposing (inWords)
import Dict
import Document
import Dom
import EditMode
import Ext.Decode exposing (traceDecoder)
import Ext.Time
import Html.Attributes.Extra exposing (intProperty)
import Html.Events.Extra exposing (onClickPreventDefaultAndStopPropagation, onClickStopPropagation)
import Json.Decode
import Json.Encode
import Keyboard.Extra exposing (Key(Enter, Escape))
import List.Extra as List
import Maybe.Extra as Maybe
import Types exposing (Entity(TodoEntity), EntityAction(ToggleDeleted))
import Msg exposing (Msg, commonMsg)
import Polymer.Attributes exposing (boolProperty, stringProperty)
import Polymer.Events exposing (onTap)
import Project
import Set
import String.Extra as String
import Svg.Events exposing (onFocusIn, onFocusOut)
import Time.Format
import Todo
import Todo.Form
import Todo.ReminderForm
import Toolkit.Helpers exposing (..)
import Toolkit.Operators exposing (..)
import Ext.Function exposing (..)
import Ext.Function.Infix exposing (..)
import Html exposing (Attribute, Html, col, div, h1, h3, span, text)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Ext.Keyboard exposing (KeyboardEvent, onEscape, onKeyDown, onKeyUp)
import Polymer.Paper as Paper
import View.Shared exposing (SharedViewModel, defaultOkCancelButtons, defaultOkCancelDeleteButtons, hideOnHover)
import WebComponents exposing (..)


initKeyed : TodoViewModel -> ( String, Html Msg )
initKeyed vm =
    ( vm.key, init vm )


init vm =
    if vm.edit.isEditing && not vm.isSelected then
        editView vm
    else
        defaultView vm


type alias EditViewModel =
    { todo : { text : Todo.Text }
    , isEditing : Bool
    , onTodoTextChanged : String -> Msg
    , onDeleteClicked : Msg
    }


createEditTodoViewModel : SharedViewModel -> Todo.Model -> EditViewModel
createEditTodoViewModel vc todo =
    let
        form =
            vc.getEditTodoForm todo

        todoId =
            form.id

        updateTodoForm =
            Msg.UpdateTodoForm form

        maybeEditTodoForm =
            vc.getMaybeEditTodoFormForTodo todo

        isEditing =
            Maybe.isJust maybeEditTodoForm
    in
        { todo =
            { text = form.todoText
            }
        , isEditing = isEditing
        , onTodoTextChanged = updateTodoForm << Todo.Form.SetText
        , onDeleteClicked = Msg.OnEntityAction (TodoEntity todo) ToggleDeleted
        }


type alias TodoViewModel =
    { text : Todo.Text
    , key : String
    , displayText : String
    , isMultiLine : Bool
    , isDone : Bool
    , isDeleted : Bool
    , projectDisplayName : String
    , contextDisplayName : String
    , selectedProjectIndex : Int
    , setContextMsg : Context.Model -> Msg
    , setProjectMsg : Project.Model -> Msg
    , startEditingMsg : Msg
    , onDoneClicked : Msg
    , onDeleteClicked : Msg
    , showDetails : Bool
    , activeContexts : List Context.Model
    , activeProjects : List Project.Model
    , onReminderButtonClicked : Msg
    , reminder : ReminderViewModel
    , edit : EditViewModel
    , onFocusIn : Msg
    , onFocus : Msg
    , onBlur : Msg
    , tabindexAV : Attribute Msg
    , isSelected : Bool
    }


type alias ReminderViewModel =
    { isEditing : Bool
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
        form =
            vc.getTodoReminderForm todo

        updateReminderForm =
            Msg.UpdateReminderForm form

        maybeReminderForm =
            vc.getMaybeTodoReminderFormForTodo todo

        isEditing =
            Maybe.isJust maybeReminderForm

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
            Todo.getDueAt todo
    in
        { isEditing = isEditing
        , date = form.date
        , time = form.time
        , displayText = displayText
        , isOverDue = displayText == overDueText
        , isSnoozed = Todo.isSnoozed todo
        , dueAtToolTipText = Todo.getDueAt todo ?|> Ext.Time.formatDateTime ?= ""
        , dayDiffInWords = dueAt ?|> Ext.Time.dayDiffInWords vc.now ?= ""
        , onDateChanged = updateReminderForm << Todo.ReminderForm.SetDate
        , onTimeChanged = updateReminderForm << Todo.ReminderForm.SetTime
        , startEditingMsg = Msg.StartEditingReminder todo
        }


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

        text =
            Todo.getText todo

        ( displayText, isMultiLine ) =
            let
                lines =
                    text |> String.trim |> String.nonEmpty ?= "< empty >" |> String.lines
            in
                case lines of
                    [] ->
                        -- never happens
                        ( "", False )

                    firstLine :: [] ->
                        ( firstLine, False )

                    firstLine :: xs ->
                        ( firstLine ++ " ...", True )

        displayText2 =
            text |> String.trim |> String.ellipsis 100

        onEntityAction =
            Msg.OnEntityAction (TodoEntity todo)
    in
        { isDone = Todo.getDone todo
        , key = todoId
        , isDeleted = Todo.getDeleted todo
        , text = text
        , isMultiLine = isMultiLine
        , displayText = displayText
        , projectDisplayName = projectDisplayName
        , contextDisplayName = contextDisplayName
        , selectedProjectIndex = vc.activeProjects |> List.findIndex (Document.hasId projectId) ?= 0
        , setContextMsg = Msg.SetTodoContext # todo
        , setProjectMsg = Msg.SetTodoProject # todo
        , startEditingMsg = Msg.StartEditingTodo todo
        , onDoneClicked = Msg.ToggleTodoDone todo
        , showDetails = vc.showDetails
        , activeContexts = vc.activeContexts
        , activeProjects = vc.activeProjects
        , onReminderButtonClicked = Msg.StartEditingReminder todo
        , reminder = createReminderViewModel vc todo
        , edit = createEditTodoViewModel vc todo
        , onDeleteClicked = onEntityAction ToggleDeleted
        , onFocusIn = onEntityAction Types.SetFocusedIn
        , onFocus = onEntityAction Types.SetFocused
        , onBlur = onEntityAction Types.SetBlurred
        , tabindexAV = tabindexAV
        , isSelected = vc.selectedEntityIdSet |> Set.member todoId
        }


defaultView : TodoViewModel -> Html Msg
defaultView vm =
    div
        [ classList [ "todo-item" => True, "selected" => vm.isSelected ]
        , onFocusIn vm.onFocusIn
        , onFocus vm.onFocus
        , onBlur vm.onBlur
        , vm.tabindexAV

        --        , onFocusIn (commonMsg.logString ("focusIn: " ++ vm.displayText))
        --        , onFocusOut (commonMsg.logString ("focusOut: " ++ vm.displayText))
        ]
        [ div [ class "layout vertical" ]
            [ div
                [ style [ "flex" => "1 1 auto" ]
                , class "text-wrap"
                , onClick vm.startEditingMsg
                ]
                [ doneIconButton vm
                , span [ class "display-text" ] [ text vm.displayText ]
                ]
            , div
                [ style [ "flex" => "0 1 auto" ]
                , class "layout horizontal end-justified"
                ]
                [ reminderView vm
                , div [ class "_flex-auto", style [ "padding" => "0 8px" ] ] [ contextDropdownMenu vm ]
                , div [ class "_flex-auto", style [ "padding" => "0 8px" ] ] [ projectDropdownMenu vm ]
                ]
            ]
        ]


dropdownTriggerWithTitle tabindexAV title =
    div [ class "font-nowrap" ] [ text title ] |> dropdownTrigger tabindexAV


dropdownTrigger tabindexAV content =
    div [ style [ "height" => "24px" ], class "layout horizontal font-body1", slotDropdownTrigger ]
        [ Paper.button [ class "padding-0 margin-0 shrink", tabindexAV ]
            [ div [ class "text-transform-none primary-text-color" ] [ content ]
            ]
        ]


contextDropdownMenu vm =
    Paper.menuButton [ style [ "min-width" => "50%" ], class "flex-auto", dynamicAlign ]
        [ dropdownTriggerWithTitle vm.tabindexAV vm.contextDisplayName
        , Paper.listbox
            [ class "dropdown-content", attribute "slot" "dropdown-content" ]
            (vm.activeContexts .|> createContextItem # vm)
        ]


projectDropdownMenu vm =
    Paper.menuButton [ style [ "min-width" => "50%" ], class "flex-auto", dynamicAlign ]
        [ dropdownTriggerWithTitle vm.tabindexAV vm.projectDisplayName
        , Paper.listbox
            [ class "dropdown-content", attribute "slot" "dropdown-content" ]
            (vm.activeProjects .|> createProjectItem # vm)
        ]


createProjectItem project vm =
    Paper.item
        [ onClickStopPropagation (vm.setProjectMsg project) ]
        [ project |> Project.getName >> text ]


createContextItem context vm =
    Paper.item
        [ onClickStopPropagation (vm.setContextMsg context) ]
        [ context |> Context.getName >> text ]


doneIconButton : TodoViewModel -> Html Msg
doneIconButton vm =
    Paper.iconButton
        [ class ("done-icon done-" ++ toString (vm.isDone))
        , onClickStopPropagation (vm.onDoneClicked)
        , iconA "done"
        , vm.tabindexAV
        ]
        []


reminderView : TodoViewModel -> Html Msg
reminderView vm =
    let
        reminderVM =
            vm.reminder

        reminderTrigger =
            if reminderVM.displayText == "" then
                iconButton "alarm-add" [ vm.tabindexAV, slotDropdownTrigger, onClick reminderVM.startEditingMsg ]
            else
                dropdownTrigger vm.tabindexAV
                    (div
                        [ onClick reminderVM.startEditingMsg
                        , classList
                            [ "reminder-text" => True
                            , "overdue" => reminderVM.isOverDue
                            ]
                        , style [ "padding" => "0 8px" ]
                        ]
                        [ icon "av:snooze" [ classList [ "display-none" => not reminderVM.isSnoozed ] ]
                        , text reminderVM.displayText
                        ]
                    )
    in
        div []
            ([ Paper.menuButton
                [ boolProperty "opened" reminderVM.isEditing
                , boolProperty "dynamicAlign" True
                , boolProperty "stopKeyboardEventPropagation" True
                ]
                [ reminderTrigger
                , div
                    [ class "static dropdown-content"
                    , attribute "slot" "dropdown-content"
                    ]
                    [ div [ class "font-subhead" ] [ text "Select date and time" ]
                    , Paper.input
                        [ type_ "date"
                        , classList [ "auto-focus" => reminderVM.isEditing ]
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
             ]
                ++ (timeToolTip reminderVM)
            )


timeToolTip vm =
    if vm.dueAtToolTipText /= "" then
        [ Paper.tooltip
            [ intProperty "offset" 0
            ]
            [ div [ class "tooltip" ]
                [ div [ class "font-body1" ] [ text vm.dueAtToolTipText ]
                , div [ class "font-caption" ] [ text vm.dayDiffInWords ]
                ]
            ]
        ]
    else
        []


editView : TodoViewModel -> Html Msg
editView vm =
    div
        [ class "todo-item editing"
        , onFocusIn vm.onFocusIn
        , onFocus vm.onFocus
        , onBlur vm.onBlur
        , vm.tabindexAV
        ]
        [ div [ class "vertical layout flex-auto" ]
            [ div [ class "flex" ]
                [ Html.node "paper-textarea"
                    [ class "auto-focus"
                    , stringProperty "label" "Todo"
                    , value (vm.edit.todo.text)
                    , property "keyBindings" Json.Encode.null
                    , boolProperty "stopKeyboardEventPropagation" True
                    , onInput vm.edit.onTodoTextChanged
                    ]
                    []
                ]
            , defaultOkCancelDeleteButtons vm.edit.onDeleteClicked
            ]
        ]
