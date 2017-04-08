module View.Todo exposing (..)

import Context
import Date.Distance exposing (inWords)
import Dict
import Dom
import Ext.Decode exposing (traceDecoder)
import Html.Attributes.Extra exposing (intProperty)
import Html.Events.Extra exposing (onClickStopPropagation)
import Json.Decode
import Json.Encode
import Keyboard.Extra exposing (Key(Enter, Escape))
import Msg exposing (Msg)
import Polymer.Attributes exposing (boolProperty, icon, stringProperty)
import Project exposing (ProjectName)
import Set
import Todo
import Toolkit.Helpers exposing (..)
import Toolkit.Operators exposing (..)
import Ext.Function exposing (..)
import Ext.Function.Infix exposing (..)
import Html exposing (div, span, text)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Ext.Keyboard exposing (KeyboardEvent, onEscape, onKeyUp)
import Polymer.Paper exposing (..)
import Todo.Types exposing (TodoId, TodoText)


textValue : Json.Decode.Decoder String
textValue =
    Json.Decode.at [ "detail", "text" ] Json.Decode.string


onAutoCompleteSelected : (String -> msg) -> Html.Attribute msg
onAutoCompleteSelected tagger =
    on "autocomplete-selected" (Json.Decode.map tagger (traceDecoder "selected" textValue))


type alias EditTodoViewModel =
    { todo : { text : TodoText, id : TodoId, inputId : Dom.Id }
    , project : { name : ProjectName, inputId : Dom.Id }
    , onKeyUp : KeyboardEvent -> Msg
    , onTodoTextChanged : TodoText -> Msg
    , onProjectNameChanged : ProjectName -> Msg
    , encodedProjectNames : Json.Encode.Value
    }


edit vm =
    item [ class "todo-item" ]
        [ itemBody []
            [ input
                [ id vm.todo.inputId
                , class "edit-todo-input auto-focus"
                , stringProperty "label" "Todo"
                , value (vm.todo.text)
                , onInput vm.onTodoTextChanged
                , autofocus True
                , onClickStopPropagation (Msg.FocusPaperInput ".edit-todo-input")
                , onKeyUp vm.onKeyUp
                ]
                []
            , input
                [ id (vm.project.inputId)
                , class "project-name-input"
                , onClickStopPropagation (Msg.FocusPaperInput ".project-name-input")
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
            , input
                [ id (vm.context.inputId)
                , class "context-name-input"
                , onClickStopPropagation (Msg.FocusPaperInput ".context-name-input")
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
            ]
        ]


default vc todo =
    let
        vm =
            let
                todoId =
                    Todo.getId todo
            in
                { onCheckBoxClicked = Msg.TodoCheckBoxClicked todo
                , isSelected = Set.member todoId vc.selection
                , projectName =
                    Todo.getMaybeProjectId todo
                        ?+> (Dict.get # vc.projectIdToNameDict)
                        ?= "<No Project>"
                , contextName =
                    Todo.getMaybeContextId todo
                        ?+> (Dict.get # vc.contextByIdDict >> Maybe.map Context.getName)
                        ?= "Inbox"
                }
    in
        item
            [ class "todo-item"
            , onClickStopPropagation (Msg.StartEditingTodo todo)
            ]
            [ checkBoxView vm
            , itemBody []
                [ span
                    [ classList
                        [ "ellipsis" => True
                        , "done" => Todo.isDone todo
                        ]
                    ]
                    [ Todo.getText todo |> text ]
                , span [ class "small dim" ]
                    [ text vm.projectName
                    , text " : "
                    , text ("created " ++ (Todo.createdAtInWords vc.now todo) ++ " ago. ")
                    , text ("modified " ++ (Todo.modifiedAtInWords vc.now todo) ++ " ago")
                    ]
                ]
            , hoverIcons vm vc todo
            , nonHoverIcons vc todo
            ]


checkBoxView vm =
    checkbox [ checked vm.isSelected, onClickStopPropagation vm.onCheckBoxClicked ] []


todoInputId todoId =
    "edit-todo-input-" ++ todoId


hoverIcons vm vc todo =
    div [ class "show-on-hover" ]
        [ --        startIconButton vc todo
          doneIconButton vc todo
        , deleteIconButton vc todo
        , moveToContextMenuIcon vm vc todo
        ]


nonHoverIcons vc todo =
    div [ class "hide-on-hover" ]
        ([] ++ (ifElse Todo.isDone (doneIconButton vc >> List.singleton) (\_ -> []) todo))


doneIconButton vc todo =
    iconButton
        [ class ("done-" ++ toString (Todo.isDone todo))
        , onClickStopPropagation (Msg.ToggleTodoDone todo)
        , icon "check"
        ]
        []


deleteIconButton vc todo =
    iconButton
        [ onClickStopPropagation
            (Msg.ToggleTodoDeleted todo)
        , icon "delete"
        ]
        []


startIconButton vc todo =
    iconButton [ onClickStopPropagation (Msg.Start todo), icon "av:play-circle-outline" ] []


moveToContextMenuIcon vm vc todo =
    menuButton
        [ onClickStopPropagation Msg.NoOp
        , attribute "horizontal-align" "right"
        ]
        [ iconButton [ icon "more-vert", class "dropdown-trigger" ] []
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
                            , onClickStopPropagation (Msg.SetTodoContext context todo)
                            ]
                            [ text (Context.getName context) ]
                    )
            )
        ]
