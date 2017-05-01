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
import View.Shared exposing (SharedViewModel, defaultOkCancelButtons, hideOnHover)
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
                    (createEditTodoViewModel >> editView vm)
    in
        ( Document.getId todo, view )


type alias EditTodoViewModel =
    { todo : { text : Todo.Text }
    , onKeyUp : KeyboardEvent -> Msg
    , onTodoTextChanged : String -> Msg
    , onSaveClicked : Msg
    , onCancelClicked : Msg
    }


createEditTodoViewModel : TodoForm -> EditTodoViewModel
createEditTodoViewModel form =
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
        , onSaveClicked = Msg.SaveCurrentForm
        , onCancelClicked = Msg.DeactivateEditingMode
        }


type alias TodoViewModel =
    { text : Todo.Text
    , time : String
    , isDone : Bool
    , isDeleted : Bool
    , isSelected : Bool
    , projectName : Project.Name
    , selectedProjectIndex : Int
    , contextName : Context.Name
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

        projectName =
            Todo.getProjectId todo
                |> (Dict.get # vc.projectByIdDict >> Maybe.map Project.getName)
                ?= "<No Project>"

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
            in
                { isEditing = isEditing
                , date = form.date
                , time = form.time
                , displayText = Todo.getMaybeTime todo ?|> Ext.Time.formatTime ?= "Someday"
                , isReminderActive = Todo.isReminderActive todo
                , onDateChanged = updateReminderForm << Todo.ReminderForm.SetDate
                , onTimeChanged = updateReminderForm << Todo.ReminderForm.SetTime
                , startEditingMsg = Msg.StartEditingReminder todo
                }
    in
        { isDone = Todo.getDone todo
        , isDeleted = Todo.getDeleted todo
        , time = Todo.getMaybeTime todo ?|> Ext.Time.formatTime ?= "Someday"
        , text = Todo.getText todo
        , isSelected = Set.member todoId vc.selection
        , projectName = projectName
        , selectedProjectIndex = projects |> List.Extra.findIndex (Project.nameEquals projectName) ?= 0
        , contextName =
            Todo.getContextId todo
                |> (Dict.get # vc.contextByIdDict >> Maybe.map Context.getName)
                ?= "Inbox"
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
            [ div [ class "layout horizontal center justified has-hover-elements" ]
                [ div [ class "font-nowrap flex-auto", onClick vm.startEditingMsg ] [ text vm.text ]
                , div [ class "layout horizontal" ]
                    [ doneIconButton vm
                    , deleteIconButton vm
                    ]
                ]
            , div [ class "layout horizontal"]
                [ reminderView vm.reminder
                , div [ class "shrink flex-auto layout horizontal center-aligned" ]
                    [ projectView vm
                    , contextView vm
                    ]
                ]
            ]
        ]


contextView vm =
    Paper.menuButton [ style [ "min-width" => "50%" ], class "flex-auto", boolProperty "dynamicAlign" True ]
        [ dropdownTrigger vm.contextName
        , Paper.listbox [ attribute "slot" "dropdown-content" ]
            (vm.contexts .|> createContextItem # vm)
        ]


dropdownTrigger title =
    Html.button [ style [ "height" => "24px" ], class "font-nowrap no-style", attribute "slot" "dropdown-trigger" ]
        [ text title ]


projectView vm =
    Paper.menuButton [ style [ "min-width" => "50%" ], class "flex-auto", boolProperty "dynamicAlign" True ]
        [ dropdownTrigger vm.projectName
        , Paper.listbox
            [ class "dropdown-content", attribute "slot" "dropdown-content" ]
            (vm.projects .|> createProjectItem # vm)
        ]


reminderView : ReminderViewModel -> Html Msg
reminderView vm =
    Paper.menuButton
        [ boolProperty "opened" vm.isEditing
        , boolProperty "dynamicAlign" True
        , boolProperty "stopKeyboardEventPropagation" True
        , class "flex-none"
        ]
        [ div
            [ onClickStopPropagation vm.startEditingMsg
            , classList
                [ "secondary-color" => not vm.isReminderActive
                , "accent-color" => vm.isReminderActive
                ]
            , attribute "slot" "dropdown-trigger"
            , style [ "width" => "8rem" ]
            ]
            [ div [ class "layout horizontal center-center" ]
                [ icon "alarm" []
                , dropdownTrigger vm.displayText
                ]
            ]

        {- , Paper.button
           [ onClickStopPropagation vm.startEditingMsg
           , classList
               [ "secondary-color" => not vm.isReminderActive
               , "accent-color" => vm.isReminderActive
               ]
           , attribute "slot" "dropdown-trigger"
           ]
           [ div [ class "layout horizontal text-transform-none font-nowrap" ]
               [ icon "alarm" []
               , div [ class "font-nowrap" ] [ text vm.displayText ]
               ]
           ]
        -}
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
            , defaultOkCancelButtons
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
        ]
        []


deleteIconButton vm =
    View.Shared.trashButton vm.onDeleteClicked
