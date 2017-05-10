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
import List.Extra
import Maybe.Extra as Maybe
import Types exposing (Entity(TodoEntity), EntityAction(ToggleDeleted))
import Msg exposing (Msg, commonMsg)
import Polymer.Attributes exposing (boolProperty, stringProperty)
import Polymer.Events exposing (onTap)
import Project
import Set
import String.Extra
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
    , onKeyUp : KeyboardEvent -> Msg
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
        , onKeyUp = Msg.EditTodoFormKeyUp form
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
    , projectName : Project.Name
    , projectDisplayName : String
    , contextName : Context.Name
    , contextDisplayName : String
    , selectedProjectIndex : Int
    , setContextMsg : Context.Model -> Msg
    , setProjectMsg : Project.Model -> Msg
    , startEditingMsg : Msg
    , onDoneClicked : Msg
    , onDeleteClicked : Msg
    , showDetails : Bool
    , contexts : List Context.Model
    , projects : List Project.Model
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

        projects =
            vc.activeProjects

        contextName =
            Todo.getContextId todo
                |> (Dict.get # vc.contextByIdDict >> Maybe.map Context.getName)
                ?= "Inbox"

        projectName =
            Todo.getProjectId todo
                |> (Dict.get # vc.projectByIdDict >> Maybe.map Project.getName)
                ?= "<No Project>"

        truncateName =
            String.Extra.ellipsis 15

        projectDisplayName =
            Todo.getProjectId todo
                |> (Dict.get # vc.projectByIdDict)
                ?|> Project.getName
                ?= ""
                |> truncateName
                |> String.append "#"

        contextDisplayName =
            Todo.getContextId todo
                |> (Dict.get # vc.contextByIdDict)
                ?|> Context.getName
                ?= "Inbox"
                |> String.append "@"
                |> truncateName

        text =
            Todo.getText todo

        ( displayText, isMultiLine ) =
            let
                lines =
                    text |> String.trim |> String.Extra.nonEmpty ?= "< empty >" |> String.lines
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
            text |> String.trim |> String.Extra.ellipsis 100

        onEntityAction =
            Msg.OnEntityAction (TodoEntity todo)
    in
        { isDone = Todo.getDone todo
        , key = todoId
        , isDeleted = Todo.getDeleted todo
        , text = text
        , isMultiLine = isMultiLine
        , displayText = displayText
        , projectName = projectName
        , projectDisplayName = projectDisplayName
        , contextDisplayName = contextDisplayName
        , selectedProjectIndex = projects |> List.Extra.findIndex (Project.nameEquals projectName) ?= 0
        , contextName = contextName
        , setContextMsg = Msg.SetTodoContext # todo
        , setProjectMsg = Msg.SetTodoProject # todo
        , startEditingMsg = Msg.StartEditingTodo todo
        , onDoneClicked = Msg.ToggleTodoDone todo
        , onDeleteClicked = onEntityAction ToggleDeleted
        , showDetails = vc.showDetails
        , contexts = vc.activeContexts
        , projects = vc.activeProjects
        , onReminderButtonClicked = Msg.StartEditingReminder todo
        , reminder = createReminderViewModel vc todo
        , edit = createEditTodoViewModel vc todo
        , onFocusIn = onEntityAction Types.FocusIn
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
                , div [ class "_flex-auto", style [ "padding" => "0 8px" ] ] [ contextMenuButton vm ]
                , div [ class "_flex-auto", style [ "padding" => "0 8px" ] ] [ projectMenuButton vm ]
                ]
            ]
        ]


dropdownTriggerWithTitle tabindexAV title =
    div [ class "font-nowrap" ] [ text title ] |> dropdownTrigger tabindexAV


dropdownTrigger tabindexAV content =
    div [ style [ "height" => "24px" ], class "layout horizontal font-body1", attribute "slot" "dropdown-trigger" ]
        [ Paper.button [ class "padding-0 margin-0 shrink", tabindexAV ]
            [ div [ class "text-transform-none primary-text-color" ] [ content ]
            ]
        ]


contextMenuButton vm =
    Paper.menuButton [ style [ "min-width" => "50%" ], class "flex-auto", dynamicAlign ]
        [ dropdownTriggerWithTitle vm.tabindexAV vm.contextDisplayName
        , Paper.listbox
            [ class "dropdown-content", attribute "slot" "dropdown-content" ]
            (vm.contexts .|> createContextItem # vm)
        ]


projectMenuButton vm =
    Paper.menuButton [ style [ "min-width" => "50%" ], class "flex-auto", dynamicAlign ]
        [ dropdownTriggerWithTitle vm.tabindexAV vm.projectDisplayName
        , Paper.listbox
            [ class "dropdown-content", attribute "slot" "dropdown-content" ]
            (vm.projects .|> createProjectItem # vm)
        ]


slotDropDownTriggerA =
    attribute "slot" "dropdown-trigger"


reminderView : TodoViewModel -> Html Msg
reminderView vm =
    let
        reminderVM =
            vm.reminder

        reminderTrigger =
            if reminderVM.displayText == "" then
                iconButton "alarm-add" [ vm.tabindexAV, slotDropDownTriggerA, onClick reminderVM.startEditingMsg ]
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
