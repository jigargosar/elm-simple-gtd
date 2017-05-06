module Todo.View exposing (..)

import Context
import Date
import Date.Distance exposing (inWords)
import Dict
import Document
import Dom
import EditMode exposing (TodoForm)
import Ext.Decode exposing (traceDecoder)
import Ext.Time
import Html.Attributes.Extra exposing (intProperty)
import Html.Events.Extra exposing (onClickPreventDefaultAndStopPropagation, onClickStopPropagation)
import Json.Decode
import Json.Encode
import Keyboard.Extra exposing (Key(Enter, Escape))
import List.Extra
import Maybe.Extra as Maybe
import Model.Types exposing (Entity(TodoEntity), EntityAction(ToggleDeleted))
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


initKeyed : SharedViewModel -> Todo.Model -> ( String, Html Msg )
initKeyed vc todo =
    let
        vm =
            createTodoViewModel vc todo

        view =
            vc.getMaybeEditTodoFormForTodo todo
                |> Maybe.unpack
                    (\_ -> defaultView vm)
                    (createEditTodoViewModel todo >> editView vm)
    in
        ( Document.getId todo, view )


type alias EditTodoViewModel =
    { todo : { text : Todo.Text }
    , onKeyUp : KeyboardEvent -> Msg
    , onTodoTextChanged : String -> Msg
    , onDeleteClicked : Msg
    }


createEditTodoViewModel : Todo.Model -> TodoForm -> EditTodoViewModel
createEditTodoViewModel todo form =
    let
        todoId =
            form.id

        updateTodoForm =
            Msg.UpdateTodoForm form
    in
        { todo =
            { text = form.todoText
            }
        , onKeyUp = Msg.EditTodoFormKeyUp form
        , onTodoTextChanged = updateTodoForm << Todo.Form.SetText
        , onDeleteClicked = Msg.OnEntityAction (TodoEntity todo) ToggleDeleted
        }


type alias TodoViewModel =
    { text : Todo.Text
    , displayText : String
    , isMultiLine : Bool
    , isDone : Bool
    , isDeleted : Bool
    , isSelected : Bool
    , projectName : Project.Name
    , projectDisplayName : String
    , contextName : Context.Name
    , contextDisplayName : String
    , selectedProjectIndex : Int
    , onCheckBoxClicked : Msg
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
    , onFocusIn : Msg
    , tabindex : Int
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


createTodoViewModel : SharedViewModel -> Todo.Model -> TodoViewModel
createTodoViewModel vc todo =
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

        createReminderViewModel : ReminderViewModel
        createReminderViewModel =
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

        focused =
            vc.mainViewListFocusedDocumentId == todoId
    in
        { isDone = Todo.getDone todo
        , isDeleted = Todo.getDeleted todo
        , text = text
        , isMultiLine = isMultiLine
        , displayText = displayText
        , isSelected = Set.member todoId vc.selection
        , projectName = projectName
        , projectDisplayName = projectDisplayName
        , contextDisplayName = contextDisplayName
        , selectedProjectIndex = projects |> List.Extra.findIndex (Project.nameEquals projectName) ?= 0
        , contextName = contextName
        , onCheckBoxClicked = Msg.TodoCheckBoxClicked todo
        , setContextMsg = Msg.SetTodoContext # todo
        , setProjectMsg = Msg.SetTodoProject # todo
        , startEditingMsg = Msg.StartEditingTodo todo
        , onDoneClicked = Msg.ToggleTodoDone todo
        , onDeleteClicked = Msg.OnEntityAction (TodoEntity todo) ToggleDeleted
        , showDetails = vc.showDetails
        , contexts = vc.activeContexts
        , projects = vc.activeProjects
        , onReminderButtonClicked = Msg.StartEditingReminder todo
        , reminder = createReminderViewModel
        , onFocusIn = Msg.SetMainViewFocusedDocumentId todoId
        , tabindex =
            if focused then
                0
            else
                -1
        }


container { isEditing, id } =
    div
        [ classList [ "todo-item" => True, "editing" => isEditing ]
        , id |> Msg.SetMainViewFocusedDocumentId |> onFocusIn
        ]


defaultView : TodoViewModel -> Html Msg
defaultView vm =
    div
        [ class "todo-item"
        , onFocusIn vm.onFocusIn
        , tabindex vm.tabindex

        --        , onFocusIn (commonMsg.logString ("focusIn: " ++ vm.displayText))
        --        , onFocusOut (commonMsg.logString ("focusOut: " ++ vm.displayText))
        ]
        [ div [ class "layout vertical" ]
            [ div
                [ style [ "flex" => "1 1 auto" ]
                , class "text-wrap"
                , onClick vm.startEditingMsg
                ]
                [ doneIconButton2 vm
                , span [ class "display-text" ] [ text vm.displayText ]
                ]
            , div
                [ style [ "flex" => "0 1 auto" ]
                , class "layout horizontal end-justified"
                ]
                [ reminderView vm.tabindex vm.reminder
                , div [ class "_flex-auto", style [ "padding" => "0 8px" ] ] [ contextMenuButton vm ]
                , div [ class "_flex-auto", style [ "padding" => "0 8px" ] ] [ projectMenuButton vm ]
                ]
            ]
        ]


dropdownTriggerWithTitle tabindexValue title =
    div [ class "font-nowrap" ] [ text title ] |> dropdownTrigger tabindexValue


dropdownTrigger tabindexValue content =
    div [ style [ "height" => "24px" ], class "layout horizontal font-body1", attribute "slot" "dropdown-trigger" ]
        [ Paper.button [ class "padding-0 margin-0 shrink", tabindex tabindexValue ]
            [ div [ class "text-transform-none primary-text-color" ] [ content ]
            ]
        ]


contextMenuButton vm =
    Paper.menuButton [ style [ "min-width" => "50%" ], class "flex-auto", dynamicAlign ]
        [ dropdownTriggerWithTitle vm.tabindex vm.contextDisplayName
        , Paper.listbox
            [ class "dropdown-content", attribute "slot" "dropdown-content" ]
            (vm.contexts .|> createContextItem # vm)
        ]


projectMenuButton vm =
    Paper.menuButton [ style [ "min-width" => "50%" ], class "flex-auto", dynamicAlign ]
        [ dropdownTriggerWithTitle vm.tabindex vm.projectDisplayName
        , Paper.listbox
            [ class "dropdown-content", attribute "slot" "dropdown-content" ]
            (vm.projects .|> createProjectItem # vm)
        ]


slotDropDownTriggerA =
    attribute "slot" "dropdown-trigger"


reminderView : Int -> ReminderViewModel -> Html Msg
reminderView tabindexValue vm =
    let
        reminderTrigger =
            if vm.displayText == "" then
                iconButton "alarm-add" [ tabindex tabindexValue, slotDropDownTriggerA, onClick vm.startEditingMsg ]
            else
                dropdownTrigger tabindexValue
                    (div
                        [ onClick vm.startEditingMsg
                        , classList
                            [ "reminder-text" => True
                            , "overdue" => vm.isOverDue
                            ]
                        , style [ "padding" => "0 8px" ]
                        ]
                        [ icon "av:snooze" [ classList [ "display-none" => not vm.isSnoozed ] ]
                        , text vm.displayText
                        ]
                    )
    in
        div []
            ([ Paper.menuButton
                [ boolProperty "opened" vm.isEditing
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
                        , classList [ "auto-focus" => vm.isEditing ]
                        , labelA "Date"
                        , value vm.date
                        , boolProperty "stopKeyboardEventPropagation" True
                        , onChange vm.onDateChanged
                        ]
                        []
                    , Paper.input
                        [ type_ "time"
                        , labelA "Time"
                        , value vm.time
                        , boolProperty "stopKeyboardEventPropagation" True
                        , onChange vm.onTimeChanged
                        ]
                        []
                    , defaultOkCancelButtons
                    ]
                ]
             ]
                ++ (timeToolTip vm)
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


editView : TodoViewModel -> EditTodoViewModel -> Html Msg
editView vm evm =
    div
        [ class "todo-item editing"
        , onFocusIn vm.onFocusIn
        , tabindex vm.tabindex
        ]
        [ div [ class "vertical layout flex-auto" ]
            [ div [ class "flex" ]
                [ Html.node "paper-textarea"
                    [ class "auto-focus"
                    , stringProperty "label" "Todo"
                    , value (evm.todo.text)
                    , property "keyBindings" Json.Encode.null
                    , boolProperty "stopKeyboardEventPropagation" True
                    , onInput evm.onTodoTextChanged
                    ]
                    []
                ]
            , defaultOkCancelDeleteButtons evm.onDeleteClicked
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


checkBoxView vm =
    Paper.checkbox
        [ checked vm.isSelected
        , onClickStopPropagation vm.onCheckBoxClicked
        ]
        []


doneIconButton : TodoViewModel -> Html Msg
doneIconButton vm =
    Paper.iconButton
        [ class ("done-" ++ toString (vm.isDone))
        , onClickStopPropagation (vm.onDoneClicked)
        , iconA "check"

        --        , class "flex-none"
        , style [ "flex" => "0 0 auto" ]
        ]
        []


doneIconButton2 : TodoViewModel -> Html Msg
doneIconButton2 vm =
    Paper.iconButton
        [ class ("done-icon done-" ++ toString (vm.isDone))
        , onClickStopPropagation (vm.onDoneClicked)
        , iconA "done"
        , tabindex vm.tabindex
        ]
        []
