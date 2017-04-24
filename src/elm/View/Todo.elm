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
import Todo.Edit
import Toolkit.Helpers exposing (..)
import Toolkit.Operators exposing (..)
import Ext.Function exposing (..)
import Ext.Function.Infix exposing (..)
import Html exposing (Html, col, div, h3, span, text)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Ext.Keyboard exposing (KeyboardEvent, onEscape, onKeyDown, onKeyUp)
import Polymer.Paper exposing (button, checkbox, dialog, dropdownMenu, input, item, itemBody, listbox, material, menu, menuButton)
import View.Shared exposing (SharedViewModel, hideOnHover)
import WebComponents exposing (icon, iconButton, iconP, ironIcon, labelA, noLabelFloatP, onBoolPropertyChanged, onPropertyChanged, paperIconButton, secondaryA, selectedA)


createKeyedItem : SharedViewModel -> Todo.Model -> ( String, Html Msg )
createKeyedItem vc todo =
    let
        notEditingView _ =
            default vc todo

        view =
            case vc.editMode of
                EditMode.EditTodo form ->
                    if Document.hasId form.id todo then
                        expanded vc form todo
                        --                        edit (createEditTodoViewModel vc todo etm)
                    else
                        notEditingView ()

                _ ->
                    notEditingView ()
    in
        ( Document.getId todo, view )


textValue : Json.Decode.Decoder String
textValue =
    Json.Decode.at [ "detail", "text" ] Json.Decode.string


onAutoCompleteSelected : (String -> msg) -> Html.Attribute msg
onAutoCompleteSelected tagger =
    on "autocomplete-selected" (Json.Decode.map tagger (traceDecoder "selected" textValue))


type alias EditTodoViewModel =
    { todo : { text : Todo.Text, id : Todo.Id, inputId : Dom.Id }
    , project : { name : Project.Name, inputId : Dom.Id }
    , context : { name : Context.Name, inputId : Dom.Id }
    , dateInputValue : String
    , timeInputValue : String
    , encodedProjectNames : Json.Encode.Value
    , encodedContextNames : Json.Encode.Value
    , projectNames : List String
    , contextList : List Context.Model
    , contextNames : List String
    , onKeyUp : KeyboardEvent -> Msg
    , onTodoTextChanged : String -> Msg
    , onProjectNameChanged : String -> Msg
    , onContextNameChanged : String -> Msg
    , onDateChanged : String -> Msg
    , onTimeChanged : String -> Msg
    , onSaveClicked : Msg
    , onCancelClicked : Msg
    , onDeleteClicked : Msg
    , onReminderMenuOpenChanged : Bool -> Msg
    }


createEditTodoViewModel : SharedViewModel -> Todo.Model -> TodoForm -> EditTodoViewModel
createEditTodoViewModel vc todo etm =
    let
        todoId =
            etm.id

        updateTodoForm =
            Msg.UpdateTodoForm etm

        contextList =
            vc.contextByIdDict |> Dict.values
    in
        { todo =
            { text = etm.todoText
            , id = todoId
            , inputId = "edit-todo-input-" ++ todoId
            }
        , project =
            { name = etm.projectName
            , inputId = "edit-todo-project-input-" ++ todoId
            }
        , context =
            { name = etm.contextName
            , inputId = "edit-todo-context-input-" ++ todoId
            }
        , dateInputValue = etm.date
        , timeInputValue = etm.time
        , onKeyUp = Msg.EditTodoFormKeyUp etm
        , onTodoTextChanged = updateTodoForm << Todo.Edit.Text
        , onProjectNameChanged = updateTodoForm << Todo.Edit.ProjectName
        , onContextNameChanged = updateTodoForm << Todo.Edit.ContextName
        , onDateChanged = updateTodoForm << Todo.Edit.Date
        , onTimeChanged = updateTodoForm << Todo.Edit.Time
        , encodedProjectNames = vc.encodedProjectNames
        , encodedContextNames = vc.encodedContextNames
        , projectNames = vc.projectIdToNameDict |> Dict.values
        , contextList = contextList
        , contextNames = List.map Context.getName contextList
        , onSaveClicked = Msg.SaveEditingEntity
        , onCancelClicked = Msg.DeactivateEditingMode
        , onDeleteClicked = Msg.OnEntityAction (TodoEntity todo) ToggleDeleted
        , onReminderMenuOpenChanged = updateTodoForm << Todo.Edit.ReminderMenuOpen
        }


edit : EditTodoViewModel -> Html Msg
edit vm =
    item [ class "todo-item editing", onKeyDown vm.onKeyUp ]
        [ Html.node "paper-input"
            --        Html.node "paper-textarea" -- todo: add after trimming newline on enter.
            [ id vm.todo.inputId
            , class "auto-focus"
            , stringProperty "label" "Todo"
            , value (vm.todo.text)
            , onInput vm.onTodoTextChanged
            , autofocus True
            ]
            []
        , div [ class "horizontal layout justified" ]
            [ input
                [ stringProperty "label" "Date"
                , type_ "date"
                , onInput vm.onDateChanged
                , value vm.dateInputValue
                ]
                []
            , input
                [ stringProperty "label" "Time"
                , type_ "time"
                , value vm.timeInputValue
                , onInput vm.onTimeChanged
                ]
                []
            ]
        , input
            [ id (vm.context.inputId)
            , onInput vm.onContextNameChanged
            , stringProperty "label" "Context Name"
            , value vm.context.name
            ]
            []
        , Html.node "paper-autocomplete-suggestions"
            [ stringProperty "for" (vm.context.inputId)
            , property "source" (vm.encodedContextNames)
            , onAutoCompleteSelected vm.onContextNameChanged
            , intProperty "minLength" 0
            ]
            []
        , View.Shared.colItemStretched
            [ input
                [ id (vm.project.inputId)
                , onInput vm.onProjectNameChanged
                , stringProperty "label" "Project Name"
                , value vm.project.name
                ]
                []
            , Html.node "paper-autocomplete-suggestions"
                [ stringProperty "for" (vm.project.inputId)
                , property "source" (vm.encodedProjectNames)
                , onAutoCompleteSelected vm.onProjectNameChanged
                , intProperty "minLength" 0
                ]
                []
            ]
        , div [ class "horizontal layout" ]
            [ button [ onClick vm.onSaveClicked ] [ "Save" |> text ]
            , button [ onClick vm.onCancelClicked ] [ "Cancel" |> text ]
            , div [ class "self-auto" ] []
            , deleteIconButton vm
            ]
        ]


type alias DefaultTodoViewModel =
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
    }


default : SharedViewModel -> Todo.Model -> Html Msg
default vc todo =
    let
        vm : DefaultTodoViewModel
        vm =
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
                        |> (Dict.get # vc.projectIdToNameDict)
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
                }
    in
        item
            [ class "todo-item"
            , onClickStopPropagation (vm.startEditingMsg)
            ]
            [ --            checkBoxView vm
              itemBody []
                [ div [] [ text vm.text ]

                --                , div [ secondaryA, class "horizontal-justified" ]
                --                    [ div [ classList [ "red" => vm.isReminderActive ] ] [ text vm.time ]
                --                    , div [] [ text vm.projectName ]
                --                    ]
                --                , debugInfo vc vm todo
                , div
                    [ classList
                        [ "secondary-color" => not vm.isReminderActive
                        , "accent-color" => vm.isReminderActive
                        , "font-body1" => True
                        ]
                    ]
                    [ text vm.time ]
                ]
            , hoverIcons vm vc

            --            , hideOnHover vm.isDone [ doneIconButton vm ]
            --            , hideOnHover vm.isDeleted [ deleteIconButton vm ]
            ]


debugInfo vc vm todo =
    div [ attribute "secondary" "true", hidden vm.showDetails ]
        [ text ("created " ++ (Todo.createdAtInWords vc.now todo) ++ " ago. ")
        , text ("modified " ++ (Todo.modifiedAtInWords vc.now todo) ++ " ago")
        ]


expanded : SharedViewModel -> Todo.Edit.Form -> Todo.Model -> Html Msg
expanded vc form todo =
    let
        vm : DefaultTodoViewModel
        vm =
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
                        |> (Dict.get # vc.projectIdToNameDict)
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
                }

        evm =
            createEditTodoViewModel vc todo form
    in
        item
            [ class "todo-item"

            --            , onClickStopPropagation (vm.startEditingMsg)
            ]
            [ div [ class "vertical layout flex-auto" ]
                [ div [ class "flex" ]
                    [ --                        div [] [ text evm.todo.text ]
                      --                          Html.node "paper-input"
                      Html.node "paper-textarea"
                        -- todo: add after trimming newline on enter.
                        [ id evm.todo.inputId
                        , class "auto-focus"
                        , stringProperty "label" "Todo"
                        , value (evm.todo.text)
                        , boolProperty "stopKeyboardEventPropagation" True
                        , onInput evm.onTodoTextChanged
                        , onKeyDown evm.onKeyUp
                        , autofocus True
                        ]
                        []
                    , div
                        [ classList
                            [ "secondary-color" => not vm.isReminderActive
                            , "accent-color" => vm.isReminderActive
                            , "font-body1" => True
                            ]
                        ]
                        [ text vm.time ]
                    ]
                , div
                    [ class "layout horizontal center" ]
                    [ --checkBoxView vm
                      div [ class "horizontal layout wrap" ]
                        [--                        iconButton "create" [ class "flex-none", onClickStopPropagation Msg.NoOp ]
                         --                          iconButton "done" [ class "flex-none", onClickStopPropagation vm.onDoneClicked ]
                         --                        , iconButton "delete" [ class "flex-none", onClickStopPropagation vm.onDeleteClicked ]
                        ]
                    ]
                , div [ class "horizontal layout" ]
                    [ reminderMenuButton form evm
                    , menuButton []
                        [ button [ class "dropdown-trigger" ]
                            [ text "#"
                            , text vm.projectName
                            , icon "arrow-drop-down" []
                            ]
                        , menu [ class "dropdown-content" ]
                            (evm.projectNames .|> createDropDownItem)
                        ]
                    , menuButton []
                        [ button [ class "dropdown-trigger" ]
                            [ text "@"
                            , text vm.contextName
                            , icon "arrow-drop-down" []
                            ]
                        , menu [ class "dropdown-content" ]
                            (evm.contextNames .|> createDropDownItem)
                        ]
                    ]
                , debugInfo vc vm todo
                ]
            ]


reminderMenuButton form evm =
    menuButton
        [ boolProperty "opened" form.reminderMenuOpen
        , onBoolPropertyChanged "opened" evm.onReminderMenuOpenChanged
        ]
        [ paperIconButton [ iconP "alarm", class "dropdown-trigger" ] []
        , div [ class "static dropdown-content" ]
            [ div [ class "font-subhead" ] [ text "Select date and time" ]
            , input
                [ type_ "date"
                , labelA "Date"
                , autofocus True
                , value form.date
                , boolProperty
                    "stopKeyboardEventPropagation"
                    True
                , onInput evm.onDateChanged
                ]
                []
            , input
                [ type_ "time"
                , labelA "Time"
                , value form.time
                , boolProperty "stopKeyboardEventPropagation" True
                , onInput evm.onTimeChanged
                ]
                []
            , div [ class "horizontal layout end-justified" ]
                [ button [ attribute "raised" "true", onClickStopPropagation evm.onSaveClicked ] [ text "Save" ]
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


todoInputId todoId =
    "edit-todo-input-" ++ todoId


hoverIcons : DefaultTodoViewModel -> SharedViewModel -> Html Msg
hoverIcons vm vc =
    div [ class "show-on-hover" ]
        [ --        startIconButton vm
          doneIconButton vm
        , deleteIconButton vm

        --        , moveToContextMenuIcon vm vc
        ]


doneIconButton : DefaultTodoViewModel -> Html Msg
doneIconButton vm =
    Polymer.Paper.iconButton
        [ class ("done-" ++ toString (vm.isDone))
        , onClickStopPropagation (vm.onDoneClicked)
        , iconP "check"
        ]
        []


deleteIconButton vm =
    View.Shared.trashButton vm.onDeleteClicked


moveToContextMenuIcon vm vc =
    menuButton
        [ onClickStopPropagation Msg.NoOp
        , attribute "horizontal-align" "right"
        ]
        [ Polymer.Paper.iconButton [ iconP "more-vert", class "dropdown-trigger" ] []
        , menu
            [ class "dropdown-content"
            , attribute "attr-for-selected" "context-name"
            , attribute "selected" vm.contextName
            ]
            (vc.contextByIdDict
                |> Dict.values
                .|> (\context ->
                        item
                            [ attribute "context-name" (Context.getName context)
                            , onClickStopPropagation (vm.setContextMsg context)
                            ]
                            [ text (Context.getName context) ]
                    )
            )
        ]
