module Todo.View exposing (..)

import Context
import Date
import Date.Distance exposing (inWords)
import Dict
import Document
import Dom
import EditMode
import Entity
import Ext.Decode exposing (traceDecoder)
import Ext.Time
import Html.Attributes.Extra exposing (intProperty)
import Html.Events.Extra exposing (onClickPreventDefaultAndStopPropagation, onClickStopPropagation)
import Json.Decode
import Json.Encode
import Keyboard.Extra as Key exposing (Key)
import List.Extra as List
import Maybe.Extra as Maybe
import Model
import Msg exposing (Msg, commonMsg)
import Polymer.Attributes exposing (boolProperty, stringProperty)
import Polymer.Events exposing (onTap)
import Project
import Regex
import RegexBuilder
import RegexBuilder.Extra as RegexBuilder
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
import Html exposing (Attribute, Html, div, h1, h3, span, text)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Ext.Keyboard exposing (KeyboardEvent, onEscape, onKeyDown, onKeyDownPreventDefault, onKeyDownStopPropagation, onKeyUp)
import Polymer.Paper as Paper
import View.Shared exposing (SharedViewModel, defaultOkCancelButtons, defaultOkCancelDeleteButtons, hideOnHover)
import WebComponents exposing (..)


initKeyed : TodoViewModel -> ( String, Html Msg )
initKeyed vm =
    ( vm.key, init vm )


init : TodoViewModel -> Html Msg
init vm =
    let
        maybeEditVM : Maybe EditViewModel
        maybeEditVM =
            {- if vm.isSelected then
                   Nothing
               else
            -}
            vm.edit

        isEditing =
            Maybe.isJust maybeEditVM
    in
        div
            [ classList [ "todo-item" => True, "selected" => vm.isSelected, "editing" => isEditing ]
            , onFocusIn vm.onFocusIn
            , onFocus vm.onFocus
            , onBlur vm.onBlur
            , vm.tabindexAV
            , onKeyDown vm.onKeyDownMsg
            , attribute "data-key" vm.key
            ]
            (maybeEditVM |> Maybe.unpack (\_ -> defaultView vm) editView)


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
    { text : Todo.Text
    , key : String
    , displayText : String
    , isDone : Bool
    , isDeleted : Bool
    , isFocused : Bool
    , onKeyDownMsg : KeyboardEvent -> Msg
    , projectDisplayName : String
    , contextDisplayName : String
    , selectedProjectIndex : Int
    , setContextMsg : Context.Model -> Msg
    , setProjectMsg : Project.Model -> Msg
    , startEditingMsg : Msg
    , toggleDoneMsg : Msg
    , onDeleteClicked : Msg
    , showDetails : Bool
    , activeContexts : List Context.Model
    , activeProjects : List Project.Model
    , onReminderButtonClicked : Msg
    , showContextDropdownMsg : Msg
    , showProjectDropdownMsg : Msg
    , reminder : ReminderViewModel
    , edit : Maybe EditViewModel
    , onFocusIn : Msg
    , onFocus : Msg
    , onBlur : Msg
    , tabindexAV : Attribute Msg
    , isSelected : Bool
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

        displayText =
            let
                cleanText =
                    text |> String.trim |> String.nonEmpty ?= "< empty >"

                ret =
                    cleanText
                        --                        |> Debug.log "cleanText"
                        |> Regex.replace (Regex.AtMost 1) (Regex.regex "\\n\\n\\n(.|\n)*") (\match -> "\n...")

                --                        |> Debug.log "displayText"
            in
                {- case cleanText |> String.lines of
                   [] ->
                       -- never happens
                       ""

                   firstLine :: [] ->
                       firstLine

                   firstLine :: xs ->
                       firstLine ++ " ..."
                -}
                ret

        createEntityActionMsg =
            Msg.OnEntityAction (Entity.TodoEntity todo)

        maybeEditTodoForm =
            vc.getMaybeEditTodoFormForTodo todo

        isFocused =
            vc.maybeFocusedEntity ?|> (Model.getEntityId >> equals todoId) ?= False

        onKeyDownMsg ({ key } as ke) =
            if Ext.Keyboard.isAnySoftKeyDown ke then
                commonMsg.noOp
            else
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
                        Msg.StartEditingProject todo

                    Key.CharC ->
                        Msg.StartEditingContext todo

                    _ ->
                        commonMsg.noOp

        startEditingMsg =
            createEntityActionMsg Entity.StartEditing

        toggleDeleteMsg =
            createEntityActionMsg Entity.ToggleDeleted

        toggleDoneMsg =
            Msg.ToggleTodoDone todoId
    in
        { isDone = Todo.getDone todo
        , key = todoId
        , isDeleted = Todo.getDeleted todo
        , isFocused = isFocused
        , onKeyDownMsg = onKeyDownMsg
        , text = text
        , displayText = displayText
        , projectDisplayName = projectDisplayName
        , contextDisplayName = contextDisplayName
        , selectedProjectIndex = vc.activeProjects |> List.findIndex (Document.hasId projectId) ?= 0
        , setContextMsg = Msg.SetTodoContext # todo
        , setProjectMsg = Msg.SetTodoProject # todo
        , showContextDropdownMsg = Msg.StartEditingContext todo
        , showProjectDropdownMsg = Msg.StartEditingProject todo
        , startEditingMsg = startEditingMsg
        , toggleDoneMsg = toggleDoneMsg
        , showDetails = vc.showDetails
        , activeContexts = vc.activeContexts
        , activeProjects = vc.activeProjects
        , onReminderButtonClicked = Msg.StartEditingReminder todo
        , reminder = createReminderViewModel vc todo
        , edit = maybeEditTodoForm ?|> createEditTodoViewModel # todo
        , onDeleteClicked = toggleDeleteMsg
        , onFocusIn = createEntityActionMsg Entity.SetFocusedIn
        , onFocus = createEntityActionMsg Entity.SetFocused
        , onBlur = createEntityActionMsg Entity.SetBlurred
        , tabindexAV = tabindexAV
        , isSelected = vc.selectedEntityIdSet |> Set.member todoId
        }


defaultView : TodoViewModel -> List (Html Msg)
defaultView vm =
    [ div [ class "" ]
        [ div
            [ class "text-break-all"
            , onClick vm.startEditingMsg
            ]
            [ doneIconButton vm
            , span [ class "display-text" ] [ text vm.displayText ]
            ]
        , div
            [ class "layout horizontal end-justified"
            ]
            [ reminderView vm
            , div [ style [ "padding" => "0 8px" ] ] [ contextDropdownMenu vm ]
            , div [ style [ "padding" => "0 8px" ] ] [ projectDropdownMenu vm ]
            ]
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


contextDropdownMenu vm =
    let
        createContextItem context =
            Paper.item
                [ onClickStopPropagation (vm.setContextMsg context) ]
                [ context |> Context.getName >> text ]
    in
        Paper.button
            [ id ("context-dropdown-" ++ vm.key)
            , style [ "height" => "24px" ]
            , class "small padding-0 margin-0 shrink"
            , vm.tabindexAV
            , onClick vm.showContextDropdownMsg
            ]
            [ div [ class "title primary-text-color" ] [ text vm.contextDisplayName ]
            ]



--        Paper.menuButton [ dynamicAlign ]
--            [ dropdownTrigger vm (text vm.contextDisplayName)
--            , Paper.listbox
--                [ class "dropdown-content", attribute "slot" "dropdown-content" ]
--                (vm.activeContexts .|> createContextItem)
--            ]


projectDropdownMenu vm =
    let
        createProjectItem project =
            Paper.item
                [ onClickStopPropagation (vm.setProjectMsg project) ]
                [ project |> Project.getName >> text ]
    in
        Paper.button
            [ id ("project-dropdown-" ++ vm.key)
            , style [ "height" => "24px" ]
            , class "small padding-0 margin-0 shrink"
            , vm.tabindexAV
            , onClick vm.showProjectDropdownMsg
            ]
            [ div [ class "title primary-text-color" ] [ text vm.projectDisplayName ]
            ]



--        Paper.menuButton [ dynamicAlign ]
--            [ dropdownTrigger vm (text vm.projectDisplayName)
--            , Paper.listbox
--                [ class "dropdown-content", attribute "slot" "dropdown-content" ]
--                (vm.activeProjects .|> createProjectItem)
--            ]


type alias ReminderViewModel =
    { isDropdownOpen : Bool
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

        isDropdownOpen =
            Maybe.isJust (vc.getMaybeTodoReminderFormForTodo todo)

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
        { isDropdownOpen = isDropdownOpen
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


reminderView : TodoViewModel -> Html Msg
reminderView vm =
    let
        reminderVM =
            vm.reminder

        reminderTrigger =
            if reminderVM.displayText == "" then
                iconButton "alarm-add" [ vm.tabindexAV, slotDropdownTrigger, onClick reminderVM.startEditingMsg ]
            else
                dropdownTrigger vm
                    (div
                        [ onClick reminderVM.startEditingMsg
                        , classList
                            [ "reminder-text" => True
                            , "overdue" => reminderVM.isOverDue
                            ]
                        ]
                        [ icon "av:snooze" [ classList [ "display-none" => not reminderVM.isSnoozed ] ]
                        , text reminderVM.displayText
                        ]
                    )

        menuButton =
            Paper.menuButton
                [ boolProperty "opened" reminderVM.isDropdownOpen
                , boolProperty "dynamicAlign" True
                , boolProperty "stopKeyboardEventPropagation" True
                ]
                [ reminderTrigger
                , div
                    [ class "static"
                    , attribute "slot" "dropdown-content"
                    ]
                    [ div [ class "font-subhead" ] [ text "Select date and time" ]
                    , Paper.input
                        [ type_ "date"
                        , classList [ "auto-focus" => reminderVM.isDropdownOpen ]
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

        timeToolTip =
            Paper.tooltip [ intProperty "offset" 0 ]
                (if reminderVM.dueAtToolTipText /= "" then
                    [ div [ class "tooltip" ]
                        [ div [ class "font-body1 font-nowrap" ] [ text reminderVM.dueAtToolTipText ]
                        , div [ class "font-caption" ] [ text reminderVM.dayDiffInWords ]
                        ]
                    ]
                 else
                    []
                )
    in
        div [ style [ "position" => "relative" ] ]
            [ menuButton, timeToolTip ]


type alias EditViewModel =
    { todo : { text : Todo.Text }
    , onTodoTextChanged : String -> Msg
    , onDeleteClicked : Msg
    }


createEditTodoViewModel : Todo.Form.Model -> Todo.Model -> EditViewModel
createEditTodoViewModel form todo =
    let
        todoId =
            form.id

        updateTodoForm =
            Msg.UpdateTodoForm form
    in
        { todo =
            { text = form.todoText
            }
        , onTodoTextChanged = updateTodoForm << Todo.Form.SetText
        , onDeleteClicked = Msg.OnEntityAction (Entity.TodoEntity todo) Entity.ToggleDeleted
        }


editView : EditViewModel -> List (Html Msg)
editView edit =
    [ div [ class "vertical layout flex-auto" ]
        [ div [ class "flex" ]
            [ div [ class "input-field", onKeyDownStopPropagation (\_ -> commonMsg.logString "sp") ]
                [ Html.textarea
                    [ class "materialize-textarea auto-focus"

                    --                    , attribute "data-original-height" "0"
                    , defaultValue (edit.todo.text)
                    , onInput edit.onTodoTextChanged
                    ]
                    []
                , Html.label [] [ text "Todo" ]
                ]

            {- , Html.node "paper-textarea"
               [ class "_auto-focus"
               , stringProperty "label" "Todo"
               , value (edit.todo.text)

               -- for when we need custom handling for enter key
               , property "keyBindings" Json.Encode.null

               -- so that space key doesn't buble up
               , boolProperty "stopKeyboardEventPropagation" True
               , onInput edit.onTodoTextChanged
               ]
               []
            -}
            ]
        , defaultOkCancelDeleteButtons edit.onDeleteClicked
        ]
    ]
