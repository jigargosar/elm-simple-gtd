module View.Todo exposing (..)

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
import Maybe.Extra
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
import Html exposing (Html, col, div, h1, h3, span, text)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Ext.Keyboard exposing (KeyboardEvent, onEscape, onKeyDown, onKeyUp)
import Polymer.Paper as Paper
import View.Shared exposing (SharedViewModel, hideOnHover)
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
                |> Maybe.Extra.unpack
                    (\_ -> default vm (vc.getTodoReminderForm todo))
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

    --    , onReminderButtonClicked : Msg
    }


createTodoViewModel vc todo =
    let
        todoId =
            Document.getId todo
    in
        { isDone = Todo.getDone todo
        , isDeleted = Todo.getDeleted todo
        , time = Todo.getMaybeTime todo ?|> Ext.Time.formatTime ?= "Someday"
        , text = Todo.getText todo
        , isSelected = Set.member todoId vc.selection
        , projectName =
            Todo.getProjectId todo
                |> (Dict.get # vc.projectByIdDict >> Maybe.map Project.getName)
                ?= "<No Project>"
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
        }


default : TodoViewModel -> Todo.ReminderForm.Model -> Html Msg
default vm reminderForm =
    let
        updateReminderForm =
            Msg.UpdateReminderForm reminderForm

        reminderVM =
            { onDateChanged = updateReminderForm << Todo.ReminderForm.Date
            , onTimeChanged = updateReminderForm << Todo.ReminderForm.Time
            , onReminderMenuOpenChanged = updateReminderForm << Todo.ReminderForm.ReminderMenuOpen
            , onSaveClicked = Msg.SaveCurrentForm
            , startEditingMsg = Msg.StartEditingReminder reminderForm
            }
    in
        Paper.item
            [ classList [ "todo-item" => True ]
            , onClickStopPropagation (vm.startEditingMsg)
            ]
            [ Paper.itemBody []
                [ div [ class "layout horizontal center justified has-hover-elements" ]
                    [ div [ class "font-nowrap", style [ "padding" => "12px 0" ] ] [ text vm.text ]
                    , span
                        [ classList
                            [ "show-on-hover" => not reminderForm.reminderMenuOpen
                            , "layout horizontal " => True
                            ]
                        ]
                        [ doneIconButton vm
                        , reminderMenuButton reminderForm reminderVM
                        , deleteIconButton vm
                        ]
                    ]
                , div [ class "layout horizontal ", attribute "secondary" "true" ]
                    [ div
                        [ classList
                            [ "secondary-color" => not vm.isReminderActive
                            , "accent-color" => vm.isReminderActive
                            , "font-body1" => True
                            ]
                        ]
                        [ text vm.time ]
                    , div [ style [ "margin-left" => "1rem" ] ] [ text "#", text vm.projectName ]
                    , div [ style [ "margin-left" => "1rem" ] ] [ text "@", text vm.contextName ]
                    ]
                ]

            --            , span [ classList [ "show-on-hover" => not reminderForm.reminderMenuOpen ] ]
            --                [ doneIconButton vm
            --                , reminderMenuButton reminderForm reminderVM
            --                , deleteIconButton vm
            --                ]
            ]


reminderMenuButton form reminderVM =
    Paper.menuButton
        [ boolProperty "opened" form.reminderMenuOpen
        , onBoolPropertyChanged "opened" reminderVM.onReminderMenuOpenChanged
        , boolProperty "dynamicAlign" True
        , boolProperty "noOverlap" True
        , onClickStopPropagation Msg.NoOp
        , boolProperty "stopKeyboardEventPropagation" True
        ]
        [ paperIconButton
            [ iconP "alarm"
            , class "dropdown-trigger"
            , onClickStopPropagation Msg.AutoFocusPaperInput
            ]
            []
        , div
            [ class "static dropdown-content"
            ]
            [ div [ class "font-subhead" ] [ text "Select date and time" ]
            , Paper.input
                [ type_ "date"
                , classList [ "auto-focus" => form.reminderMenuOpen ]
                , labelA "Date"
                , value form.date
                , boolProperty "stopKeyboardEventPropagation" True
                , onInput reminderVM.onDateChanged
                ]
                []
            , Paper.input
                [ type_ "time"
                , labelA "Time"
                , value form.time
                , boolProperty "stopKeyboardEventPropagation" True
                , onInput reminderVM.onTimeChanged
                ]
                []
            , div [ class "horizontal layout" ]
                [ Paper.button
                    [ attribute "raised" "true"
                    , onClick reminderVM.onSaveClicked
                    , boolProperty "stopKeyboardEventPropagation" True
                    ]
                    [ text "Save" ]
                ]
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
                    , boolProperty "stopKeyboardEventPropagation" True
                    , onInput evm.onTodoTextChanged
                    , onKeyDown evm.onKeyUp
                    ]
                    []
                ]
            , div [ class "horizontal layout" ]
                [ Paper.menuButton [ boolProperty "dynamicAlign" True ]
                    [ Paper.button [ class "dropdown-trigger" ]
                        [ text "#"
                        , text vm.projectName
                        , icon "arrow-drop-down" []
                        ]
                    , Paper.menu [ class "dropdown-content" ]
                        (vm.projects .|> createProjectItem # vm)
                    ]
                , Paper.menuButton [ boolProperty "dynamicAlign" True ]
                    [ Paper.button [ class "dropdown-trigger" ]
                        [ text "@"
                        , text vm.contextName
                        , icon "arrow-drop-down" []
                        ]
                    , Paper.menu [ class "dropdown-content" ]
                        (vm.contexts .|> createContextItem # vm)
                    ]
                ]
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
