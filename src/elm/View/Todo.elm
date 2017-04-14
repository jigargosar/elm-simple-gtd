module View.Todo exposing (..)

import Context
import Date.Distance exposing (inWords)
import Dict
import Document
import Dom
import EditMode exposing (EditTodoModel)
import Ext.Decode exposing (traceDecoder)
import Html.Attributes.Extra exposing (intProperty)
import Html.Events.Extra exposing (onClickStopPropagation)
import Json.Decode
import Json.Encode
import Keyboard.Extra exposing (Key(Enter, Escape))
import Maybe.Extra
import Msg exposing (Msg)
import Polymer.Attributes exposing (boolProperty, icon, stringProperty)
import Project
import Set
import Todo
import Toolkit.Helpers exposing (..)
import Toolkit.Operators exposing (..)
import Ext.Function exposing (..)
import Ext.Function.Infix exposing (..)
import Html exposing (Html, div, span, text)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Ext.Keyboard exposing (KeyboardEvent, onEscape, onKeyUp)
import Polymer.Paper exposing (..)
import View.Shared exposing (SharedViewModel)


listItemView vc todo =
    let
        notEditingView _ =
            default vc todo

        view =
            case vc.maybeEditTodoModel of
                Just etm ->
                    if Document.hasId etm.todoId todo then
                        (edit (createEditTodoViewModel vc etm))
                    else
                        notEditingView ()

                Nothing ->
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
    , onKeyUp : KeyboardEvent -> Msg
    , onTodoTextChanged : Todo.Text -> Msg
    , onProjectNameChanged : Project.Name -> Msg
    , onContextNameChanged : Context.Name -> Msg
    , encodedProjectNames : Json.Encode.Value
    , encodedContextNames : Json.Encode.Value
    }


createEditTodoViewModel : SharedViewModel -> EditTodoModel -> EditTodoViewModel
createEditTodoViewModel vc etm =
    let
        todoId =
            etm.todoId
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
        , onKeyUp = Msg.EditTodoKeyUp etm
        , onTodoTextChanged = Msg.EditTodoTextChanged etm
        , onProjectNameChanged = Msg.EditTodoProjectNameChanged etm
        , onContextNameChanged = Msg.EditTodoContextNameChanged etm
        , encodedProjectNames = vc.encodedProjectNames
        , encodedContextNames = vc.encodedContextNames
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


type alias DefaultTodoViewModel =
    { text : String
    , isDone : Bool
    , isDeleted : Bool
    , isSelected : Bool
    , projectName : String
    , contextName : String
    , onCheckBoxClicked : Msg
    , setContextMsg : Context.Model -> Msg
    , startEditingMsg : Msg
    , onDoneClicked : Msg
    , onDeleteClicked : Msg
    }


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
                , onDeleteClicked = Msg.ToggleTodoDeleted todo
                }
    in
        item
            [ class "todo-item"
            , onClickStopPropagation (vm.startEditingMsg)
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
            , hoverIcons vm vc
            , nonHoverIcons vm
            ]


checkBoxView vm =
    checkbox [ checked vm.isSelected, onClickStopPropagation vm.onCheckBoxClicked ] []


todoInputId todoId =
    "edit-todo-input-" ++ todoId


hoverIcons : DefaultTodoViewModel -> SharedViewModel -> Html Msg
hoverIcons vm vc =
    div [ class "show-on-hover" ]
        [ --        startIconButton vm
          doneIconButton vm
        , deleteIconButton vm
        , moveToContextMenuIcon vm vc
        ]


nonHoverIcons : DefaultTodoViewModel -> Html Msg
nonHoverIcons vm =
    div [ class "hide-on-hover" ]
        ([] ++ (doneNonHoverIcon vm |> Maybe.Extra.toList) ++ (deleteNonHoverIcon vm |> Maybe.Extra.toList))


doneNonHoverIcon : DefaultTodoViewModel -> Maybe (Html Msg)
doneNonHoverIcon vm =
    if vm.isDone then
        Just (doneIconButton vm)
    else
        Nothing


deleteNonHoverIcon : DefaultTodoViewModel -> Maybe (Html Msg)
deleteNonHoverIcon vm =
    if vm.isDeleted then
        Just (deleteIconButton vm)
    else
        Nothing


doneIconButton : DefaultTodoViewModel -> Html Msg
doneIconButton vm =
    iconButton
        [ class ("done-" ++ toString (vm.isDone))
        , onClickStopPropagation (vm.onDoneClicked)
        , icon "check"
        ]
        []


deleteIconButton vm =
    iconButton
        [ onClickStopPropagation vm.onDeleteClicked
        , icon "delete"
        ]
        []


startIconButton vc todo =
    iconButton [ onClickStopPropagation (Msg.Start todo), icon "av:play-circle-outline" ] []


moveToContextMenuIcon vm vc =
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
                            , onClickStopPropagation (vm.setContextMsg context)
                            ]
                            [ text (Context.getName context) ]
                    )
            )
        ]
