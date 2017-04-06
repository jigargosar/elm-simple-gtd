module View.Todo exposing (..)

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
            ]
        ]


todoViewNotEditing vc todo =
    let
        projectName =
            Todo.getMaybeProjectId todo ?+> Dict.get # vc.projectIdToNameDict ?= "<No Project>"
    in
        item
            [ class "todo-item"
            , onClickStopPropagation (Msg.StartEditingTodo todo)
            ]
            [ checkBoxView todo
            , itemBody []
                [ span
                    [ classList
                        [ "ellipsis" => True
                        , "done" => Todo.isDone todo
                        ]
                    ]
                    [ Todo.getText todo |> text ]
                , span [ class "small dim" ]
                    [ text projectName
                    , text " : "
                    , text ("created " ++ (Todo.createdAtInWords vc.now todo) ++ " ago. ")
                    , text ("modified " ++ (Todo.modifiedAtInWords vc.now todo) ++ " ago")
                    ]
                ]
            , hoverIcons vc todo
            , nonHoverIcons vc todo
            ]


checkBoxView =
    checkbox [ checked False, onClickStopPropagation Msg.TodoCheckBoxClicked ] []


todoInputId todoId =
    "edit-todo-input-" ++ todoId


hoverIcons vc todo =
    div [ class "show-on-hover" ]
        [ --        startIconButton vc todo
          doneIconButton vc todo
        , deleteIconButton vc todo
        , optionsIconButton vc todo
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


optionsIconButton vc todo =
    menuButton
        [ onClickStopPropagation Msg.NoOp
        , attribute "horizontal-align" "right"
        ]
        [ iconButton [ icon "more-vert", class "dropdown-trigger" ] []
        , menu
            [ class "dropdown-content"
            , attribute "attr-for-selected" "list-type"
            , attribute "selected" (Todo.getContextName todo)
            ]
            (Todo.getAllTodoContexts
                .|> (\context ->
                        item
                            [ attribute "list-type" (Todo.todoContextToName context)
                            , onClickStopPropagation (Msg.SetTodoContext context todo)
                            ]
                            [ text (Todo.todoContextToName context) ]
                    )
            )
        ]
