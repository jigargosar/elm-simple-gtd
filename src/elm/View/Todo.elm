module View.Todo exposing (..)

import Date.Distance exposing (inWords)
import DecodeExtra exposing (traceDecoder)
import Html.Attributes.Extra exposing (intProperty)
import Html.Events.Extra exposing (onClickStopPropagation)
import Json.Decode
import Json.Encode
import Keyboard.Extra exposing (Key(Enter, Escape))
import Msg
import Polymer.Attributes exposing (boolProperty, icon, stringProperty)
import Todo
import Toolkit.Helpers exposing (..)
import Toolkit.Operators exposing (..)
import FunctionExtra exposing (..)
import FunctionExtra.Operators exposing (..)
import Html exposing (div, span, text)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import KeyboardExtra exposing (onEscape, onKeyUp)
import Polymer.Paper exposing (..)


textValue : Json.Decode.Decoder String
textValue =
    Json.Decode.at [ "detail", "text" ] Json.Decode.string


onAutoCompleteSelected : (String -> msg) -> Html.Attribute msg
onAutoCompleteSelected tagger =
    on "autocomplete-selected" (Json.Decode.map tagger (traceDecoder "selected" textValue))


getEncodedProjectNames =
    Json.Encode.list [ Json.Encode.string "Foo" ]


todoViewEditing vc etm =
    item [ class "todo-item" ]
        [ itemBody []
            [ input
                [ id (todoInputId etm.todoId)
                , class "edit-todo-input auto-focus"
                , stringProperty "label" "Todo"
                , value (etm.todoText)
                , onInput Msg.EditTodoTextChanged
                , autofocus True
                , onClickStopPropagation (Msg.FocusPaperInput ".edit-todo-input")
                , onKeyUp Msg.EditTodoKeyUp
                ]
                []
            , input
                [ id (todoProjectInputId etm.todoId)
                , class "project-name-input"
                , onClickStopPropagation (Msg.FocusPaperInput ".project-name-input")
                , onInput Msg.EditTodoProjectNameChanged
                , stringProperty "label" "Project Name"
                , value etm.projectName
                ]
                []
            , Html.node "paper-autocomplete-suggestions"
                [ stringProperty "for" (todoProjectInputId etm.todoId)
                , property "source" (vc.encodedProjectNames)
                , onAutoCompleteSelected Msg.EditTodoProjectNameChanged
                , intProperty "minLength" 0
                ]
                []
            ]
        ]


todoViewNotEditing vc todo =
    item
        [ class "todo-item"
        , onClickStopPropagation (Msg.StartEditingTodo todo)
        ]
        [ checkBoxView
        , itemBody []
            [ span
                [ classList
                    [ "ellipsis" => True
                    , "done" => Todo.isDone todo
                    ]
                ]
                [ Todo.getText todo |> text ]
            , span [ class "small dim" ]
                [ text ("created " ++ (Todo.createdAtInWords vc.now todo) ++ " ago. ")
                , text ("modified " ++ (Todo.modifiedAtInWords vc.now todo) ++ " ago")
                ]
            ]
        , hoverIcons vc todo
        , nonHoverIcons vc todo
        ]


checkBoxView =
    checkbox [ checked False ] []


todoInputId todoId =
    "edit-todo-input-" ++ todoId


todoProjectInputId todoId =
    "edit-todo-project-input-" ++ todoId


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
        , onClickStopPropagation (Msg.ToggleTodoDone (Todo.getId todo))
        , icon "check"
        ]
        []


deleteIconButton vc todo =
    iconButton
        [ onClickStopPropagation
            (Msg.ToggleTodoDeleted (Todo.getId todo))
        , icon "delete"
        ]
        []


startIconButton vc todo =
    iconButton [ onClickStopPropagation (Msg.Start (Todo.getId todo)), icon "av:play-circle-outline" ] []


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
                            , onClickStopPropagation (Msg.SetTodoContext context (Todo.getId todo))
                            ]
                            [ text (Todo.todoContextToName context) ]
                    )
            )
        ]
