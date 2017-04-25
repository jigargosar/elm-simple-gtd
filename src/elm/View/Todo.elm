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
import Html.Events.Extra exposing (onClickStopPropagation)
import Json.Decode
import Json.Encode
import Keyboard.Extra exposing (Key(Enter, Escape))
import Maybe.Extra
import Model.Types exposing (Entity(TodoEntity), EntityAction(ToggleDeleted))
import Msg exposing (Msg)
import Polymer.Attributes exposing (boolProperty, stringProperty)
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
import Polymer.Paper exposing (button, checkbox, dialog, dropdownMenu, input, item, itemBody, listbox, material, menu, menuButton)
import View.Shared exposing (SharedViewModel, hideOnHover)
import WebComponents exposing (icon, iconButton, iconP, ironIcon, labelA, noLabelFloatP, onBoolPropertyChanged, onPropertyChanged, paperIconButton, secondaryA, selectedA, testDialog)


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
        , onSaveClicked = Msg.SaveEditingEntity
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
    , startEditingMsg : Msg
    , onDoneClicked : Msg
    , onDeleteClicked : Msg
    , showDetails : Bool
    , isReminderActive : Bool
    , onReminderButtonClicked : Msg
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
        , startEditingMsg = Msg.StartEditingTodo todo
        , onDoneClicked = Msg.ToggleTodoDone todo
        , onDeleteClicked = Msg.OnEntityAction (TodoEntity todo) ToggleDeleted
        , showDetails = vc.showDetails
        , isReminderActive = Todo.isReminderActive todo
        , onReminderButtonClicked = Msg.StartEditingReminder todo
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
            , onSaveClicked = Msg.SaveEditingEntity
            }
    in
        item
            [ class "todo-item"
            , onClickStopPropagation (vm.startEditingMsg)
            ]
            [ itemBody []
                [ div [] [ text vm.text ]
                , div [ class "layout horizontal", attribute "secondary" "true" ]
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
            , div [ class "show-on-hover" ]
                [ doneIconButton vm
                , reminderMenuButton reminderForm reminderVM
                , deleteIconButton vm
                ]
            ]


editView : TodoViewModel -> EditTodoViewModel -> Html Msg
editView vm evm =
    let
        projectNames =
            [ "fooprj", "barprj" ]

        contextNames =
            [ "@fooC", "@barC" ]
    in
        item
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
                        , autofocus True
                        ]
                        []
                    ]
                , div [ class "horizontal layout" ]
                    [ menuButton []
                        [ button [ class "dropdown-trigger" ]
                            [ text "#"
                            , text vm.projectName
                            , icon "arrow-drop-down" []
                            ]
                        , menu [ class "dropdown-content" ]
                            (projectNames .|> createDropDownItem)
                        ]
                    , menuButton []
                        [ button [ class "dropdown-trigger" ]
                            [ text "@"
                            , text vm.contextName
                            , icon "arrow-drop-down" []
                            ]
                        , menu [ class "dropdown-content" ]
                            (contextNames .|> createDropDownItem)
                        ]
                    ]
                ]
            ]


reminderMenuButton form reminderVM =
    menuButton
        [ boolProperty "opened" form.reminderMenuOpen
        , onBoolPropertyChanged "opened" reminderVM.onReminderMenuOpenChanged
        ]
        [ paperIconButton [ iconP "alarm", class "dropdown-trigger" ] []
        , div [ class "static dropdown-content" ]
            [ div [ class "font-subhead" ] [ text "Select date and time" ]
            , input
                [ type_ "date"
                , labelA "Date"
                , autofocus True
                , value form.date
                , boolProperty "stopKeyboardEventPropagation" True
                , onInput reminderVM.onDateChanged
                ]
                []
            , input
                [ type_ "time"
                , labelA "Time"
                , value form.time
                , boolProperty "stopKeyboardEventPropagation" True
                , onInput reminderVM.onTimeChanged
                ]
                []
            , div [ class "horizontal layout end-justified" ]
                [ button [ attribute "raised" "true", onClickStopPropagation reminderVM.onSaveClicked ]
                    [ text "Save" ]
                ]
            ]
        ]


createDropDownItem title =
    item [] [ text title ]


checkBoxView vm =
    checkbox
        [ checked vm.isSelected
        , onClickStopPropagation vm.onCheckBoxClicked
        ]
        []


doneIconButton : TodoViewModel -> Html Msg
doneIconButton vm =
    Polymer.Paper.iconButton
        [ class ("done-" ++ toString (vm.isDone))
        , onClickStopPropagation (vm.onDoneClicked)
        , iconP "check"
        ]
        []


deleteIconButton vm =
    View.Shared.trashButton vm.onDeleteClicked
