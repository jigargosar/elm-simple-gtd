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
import Msg exposing (Msg)
import Polymer.Attributes exposing (boolProperty, stringProperty)
import Polymer.Events exposing (onTap)
import Project
import Set
import String.Extra
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


createKeyedItem : SharedViewModel -> Todo.Model -> ( String, Html Msg )
createKeyedItem vc todo =
    let
        vm =
            createTodoViewModel vc todo

        maybeReminderForm =
            vc.getMaybeTodoReminderFormForTodo todo

        view =
            vc.getMaybeEditTodoFormForTodo todo
                |> Maybe.unpack
                    (\_ -> default vm maybeReminderForm (vc.getTodoReminderForm todo))
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
    , isReminderActive : Bool
    , contexts : List Context.Model
    , projects : List Project.Model
    , onReminderButtonClicked : Msg
    , reminder : ReminderViewModel
    }


type alias ReminderViewModel =
    { isEditing : Bool
    , date : String
    , time : String
    , displayText : String
    , isOverDue : Bool
    , isReminderActive : Bool
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

        truncateString =
            String.Extra.ellipsis 15

        projectDisplayName =
            Todo.getProjectId todo
                |> (Dict.get # vc.projectByIdDict)
                ?|> (Project.getName >> truncateString)
                ?= ""

        contextDisplayName =
            Todo.getContextId todo
                |> (Dict.get # vc.contextByIdDict)
                ?|> (Context.getName >> truncateString)
                ?= "Inbox"

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

                format time =
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

                displayText =
                    Todo.getMaybeTime todo ?|> format ?= ""
            in
                { isEditing = isEditing
                , date = form.date
                , time = form.time
                , displayText = displayText
                , isOverDue = displayText == overDueText
                , isReminderActive = Todo.isReminderActive todo
                , onDateChanged = updateReminderForm << Todo.ReminderForm.SetDate
                , onTimeChanged = updateReminderForm << Todo.ReminderForm.SetTime
                , startEditingMsg = Msg.StartEditingReminder todo
                }
    in
        { isDone = Todo.getDone todo
        , isDeleted = Todo.getDeleted todo
        , text = Todo.getText todo
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
        , isReminderActive = Todo.isReminderActive todo
        , contexts = vc.activeContexts
        , projects = vc.activeProjects
        , onReminderButtonClicked = Msg.StartEditingReminder todo
        , reminder = createReminderViewModel
        }


createReminderVM form startEditingMsg =
    let
        updateReminderForm =
            Msg.UpdateReminderForm form
    in
        { form = form
        , onDateChanged = updateReminderForm << Todo.ReminderForm.SetDate
        , onTimeChanged = updateReminderForm << Todo.ReminderForm.SetTime
        , onSaveClicked = Msg.SaveCurrentForm
        , startEditingMsg = startEditingMsg
        }


default : TodoViewModel -> Maybe Todo.ReminderForm.Model -> Todo.ReminderForm.Model -> Html Msg
default vm maybeReminderForm reminderForm =
    Paper.item
        [ classList [ "todo-item" => True ]
        ]
        [ Paper.itemBody []
            [ div [ class "layout horizontal center justified" ]
                [ doneIconButton vm
                , div [ class "font-nowrap flex-auto", onClick vm.startEditingMsg ]
                    [ text vm.text ]
                , div [ class "layout horizontal center secondary-color font-body1" ]
                    [ div []
                        [ reminderView vm.reminder ]
                    , div
                        [ classList
                            [ "display-none" => (vm.projectDisplayName == "")
                            ]
                        ]
                        [ vm.projectDisplayName |> text ]
                    , div []
                        [ vm.contextDisplayName |> text ]
                    ]
                ]
            , div [ class "layout horizontal" ]
                [ {- reminderView vm.reminder
                     ,
                  -}
                  div [ class "shrink flex-auto layout horizontal center-aligned" ]
                    [ projectView vm
                    , contextView vm
                    ]
                ]
            ]
        ]


dropdownTriggerWithTitle title =
    div [ class "font-nowrap" ] [ text title ] |> dropdownTrigger


dropdownTrigger content =
    div [ style [ "height" => "24px" ], class "layout horizontal font-body1", attribute "slot" "dropdown-trigger" ]
        [ Paper.button [ class "padding-0 margin-0 shrink" ]
            [ div [ class "text-transform-none secondary-color font-nowrap" ] [ content ]
            ]
        ]


contextView vm =
    Paper.menuButton [ style [ "min-width" => "50%" ], class "flex-auto", boolProperty "dynamicAlign" True ]
        [ dropdownTriggerWithTitle vm.contextName
        , Paper.listbox [ class "dropdown-content", attribute "slot" "dropdown-content" ]
            (vm.contexts .|> createContextItem # vm)
        ]


projectView vm =
    Paper.menuButton [ style [ "min-width" => "50%" ], class "flex-auto", boolProperty "dynamicAlign" True ]
        [ dropdownTriggerWithTitle vm.projectName
        , Paper.listbox
            [ class "dropdown-content", attribute "slot" "dropdown-content" ]
            (vm.projects .|> createProjectItem # vm)
        ]


slotDropDownTriggerA =
    attribute "slot" "dropdown-trigger"


reminderView : ReminderViewModel -> Html Msg
reminderView vm =
    let
        reminderTrigger =
            if vm.displayText == "" then
                iconButton "alarm-add" [ slotDropDownTriggerA ]
            else
                dropdownTrigger
                    (div
                        [ onClick vm.startEditingMsg
                        , classList
                            [ "secondary-color" => not vm.isReminderActive
                            , "accent-color" => vm.isReminderActive
                            ]
                        ]
                        [ text vm.displayText ]
                    )
    in
        Paper.menuButton
            [ boolProperty "opened" vm.isEditing
            , boolProperty "dynamicAlign" True
            , boolProperty "stopKeyboardEventPropagation" True
            , class "flex-none"
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


editView : TodoViewModel -> EditTodoViewModel -> Html Msg
editView vm evm =
    Paper.item
        [ class "todo-item editing"
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
        , iconP "check"
        , class "flex-none"
        ]
        []


deleteIconButton vm =
    View.Shared.trashButton vm.onDeleteClicked
