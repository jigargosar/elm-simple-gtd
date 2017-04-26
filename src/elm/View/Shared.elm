module View.Shared exposing (..)

import Context
import Dict exposing (Dict)
import Document exposing (Id)
import EditMode exposing (EditMode, TodoForm)
import Html exposing (Html, div, span, text)
import Html.Attributes exposing (class, style, tabindex)
import Html.Attributes.Extra exposing (intProperty)
import Html.Events exposing (onClick)
import Html.Events.Extra exposing (onClickStopPropagation)
import Json.Encode
import Model
import Polymer.Attributes exposing (icon)
import Polymer.Paper exposing (badge)
import Set exposing (Set)
import Time exposing (Time)
import Toolkit.Helpers exposing (..)
import Toolkit.Operators exposing (..)
import Ext.Function exposing (..)
import Ext.Function.Infix exposing (..)
import List.Extra as List
import Maybe.Extra as Maybe
import Model.Types exposing (Model)
import Project
import Model.Internal as Model
import Project
import Todo
import Todo.Form
import Todo.ReminderForm


type alias SharedViewModel =
    { now : Time
    , getMaybeEditTodoFormForTodo : Todo.Model -> Maybe Todo.Form.Model
    , getMaybeTodoReminderFormForTodo : Todo.Model -> Maybe Todo.ReminderForm.Model
    , getTodoReminderForm : Todo.Model -> Todo.ReminderForm.Model
    , getMaybeEditEntityFormForEntityId : Document.Id -> Maybe EditMode.EntityForm
    , projectByIdDict : Dict Id Project.Model
    , contextByIdDict : Dict Id Context.Model
    , activeProjects : List Project.Model
    , activeContexts : List Context.Model
    , selection : Set Todo.Id
    , showDetails : Bool
    }


createSharedViewModel : Model -> SharedViewModel
createSharedViewModel model =
    let
        editMode =
            Model.getEditMode model

        getMaybeTodoReminderFormForTodo =
            \todo ->
                case editMode of
                    EditMode.TodoReminderForm form ->
                        if Document.hasId form.id todo then
                            Just form
                        else
                            Nothing

                    _ ->
                        Nothing

        now =
            Model.getNow model
    in
        { now = now
        , projectByIdDict = Model.getProjectByIdDict model
        , contextByIdDict = Model.getContextByIdDict model
        , activeProjects = Model.getActiveProjects model
        , activeContexts = Model.getActiveContexts model
        , selection = Model.getSelectedTodoIdSet model
        , getMaybeEditTodoFormForTodo =
            \todo ->
                case editMode of
                    EditMode.TodoForm form ->
                        if Document.hasId form.id todo then
                            Just form
                        else
                            Nothing

                    _ ->
                        Nothing
        , getMaybeTodoReminderFormForTodo = getMaybeTodoReminderFormForTodo
        , getTodoReminderForm =
            \todo ->
                todo
                    |> getMaybeTodoReminderFormForTodo
                    |> Maybe.unpack (\_ -> Todo.ReminderForm.create todo now) identity

        --    , getMaybeEditProjectFormForProject =
        --        \project ->
        --            case editMode of
        --                EditMode.EditProject form ->
        --                    if Document.hasId form.id project then
        --                        Just form
        --                    else
        --                        Nothing
        --
        --                _ ->
        --                    Nothing
        --    , getMaybeEditContextFormForContext =
        --        \context ->
        --            case editMode of
        --                EditMode.EditContext form ->
        --                    if Document.hasId form.id context then
        --                        Just form
        --                    else
        --                        Nothing
        --
        --                _ ->
        --                    Nothing
        , getMaybeEditEntityFormForEntityId =
            \entityId ->
                case editMode of
                    EditMode.EditContext form ->
                        if entityId == form.id then
                            Just form
                        else
                            Nothing

                    EditMode.EditProject form ->
                        if entityId == form.id then
                            Just form
                        else
                            Nothing

                    _ ->
                        Nothing
        , showDetails = Model.isShowDetailsKeyPressed model
        }


defaultBadge : { x | name : String, count : Int } -> Html msg
defaultBadge vm =
    --    div [ class "ellipsis" ]
    --        [ div [] [ text vm.name ]
    --        , badge [ tabindex -1, intProperty "label" (vm.count) ] []
    --        ]
    row
        [ div [ class "ellipsis" ] [ vm.name |> text ]
        , div [ style [ "margin-left" => "0.5rem" ] ] [ " (" ++ (vm.count |> toString) ++ ")" |> text ]
        ]


row =
    div [ class "row" ]


rowItemStretched =
    div [ class "row-item-stretched" ]


colItemStretched =
    div [ class "col-item-stretched" ]


col =
    div [ class "col" ]


expand =
    div [ class "flex11" ]


sharedIconButton iconName onClickHandler =
    Polymer.Paper.iconButton [ icon iconName, onClickStopPropagation onClickHandler ] []


startIconButton =
    sharedIconButton "av:play-circle-outline"


trashIcon =
    Html.node "iron-icon" [ icon "delete" ] []


trashButton =
    sharedIconButton "delete"


doneButton =
    sharedIconButton "done"


cancelButton =
    sharedIconButton "cancel"


dismissButton =
    sharedIconButton "cancel"


snoozeButton =
    sharedIconButton "av:snooze"


settingsButton =
    sharedIconButton "settings"


showOnHover =
    div [ class "show-on-hover" ]


hideOnHover bool children =
    div [ class "hide-on-hover" ]
        (if bool then
            children
         else
            []
        )
