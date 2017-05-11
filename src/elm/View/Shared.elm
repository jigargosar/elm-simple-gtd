module View.Shared exposing (..)

import Context
import Dict exposing (Dict)
import Document exposing (Id)
import EditMode exposing (EditForm)
import Entity.ViewModel
import Html exposing (Html, div, span, text)
import Html.Attributes exposing (class, style, tabindex)
import Html.Attributes.Extra exposing (boolProperty, intProperty)
import Html.Events exposing (onClick)
import Html.Events.Extra exposing (onClickStopPropagation)
import Json.Encode
import Model
import Msg
import Polymer.Attributes exposing (icon)
import Polymer.Paper as Paper exposing (badge)
import Set exposing (Set)
import Time exposing (Time)
import Toolkit.Helpers exposing (..)
import Toolkit.Operators exposing (..)
import Ext.Function exposing (..)
import Ext.Function.Infix exposing (..)
import List.Extra as List
import Maybe.Extra as Maybe
import Types exposing (Entity, Model)
import Project
import Model.Internal as Model
import Project
import Todo
import Todo.Form
import Todo.ReminderForm


type alias AppViewModel =
    { contexts : List Entity.ViewModel.EntityViewModel
    }


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
    , showDetails : Bool
    , selectedEntityIdSet : Set Document.Id
    , maybeFocusedEntity : Maybe Entity
    }


createSharedViewModel : Model -> SharedViewModel
createSharedViewModel model =
    let
        editMode =
            Model.getEditMode model

        getMaybeTodoReminderFormForTodo =
            \todo ->
                case editMode of
                    EditMode.EditTodoReminder form ->
                        if Document.hasId form.id todo then
                            Just form
                        else
                            Nothing

                    _ ->
                        Nothing

        now =
            Model.getNow model

        getMaybeEditTodoFormForTodo =
            \todo ->
                case editMode of
                    EditMode.EditTodo form ->
                        if Document.hasId form.id todo then
                            Just form
                        else
                            Nothing

                    _ ->
                        Nothing
    in
        { now = now
        , maybeFocusedEntity = model.maybeFocusedEntity
        , selectedEntityIdSet = model.selectedEntityIdSet
        , projectByIdDict = Model.getProjectsAsIdDict model
        , contextByIdDict = Model.getContextsAsIdDict model
        , activeProjects = Model.getActiveProjects model
        , activeContexts = Model.getActiveContexts model
        , getMaybeEditTodoFormForTodo = getMaybeEditTodoFormForTodo
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
    div [ class "layout horizontal center" ]
        [ div [ class "ellipsis" ] [ vm.name |> text ]
        , div [ style [ "padding" => "0 0 1rem 0.1rem " ], class "text-secondary" ]
            [ " " ++ (vm.count |> toString) ++ "" |> text ]
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
    Paper.iconButton [ icon iconName, onClickStopPropagation onClickHandler ] []


doneButton =
    sharedIconButton "done"


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


defaultOkCancelButtons =
    okCancelButtons Msg.SaveCurrentForm Msg.DeactivateEditingMode


defaultOkCancelDeleteButtons deleteMsg =
    okCancelDeleteButtons Msg.SaveCurrentForm Msg.DeactivateEditingMode deleteMsg


layoutHorizontalReverse =
    div [ class "layout horizontal-reverse" ]


okCancelButtons okMsg cancelMsg =
    layoutHorizontalReverse
        [ okButton okMsg
        , cancelButton cancelMsg
        ]


okCancelDeleteButtons okMsg cancelMsg deleteMsg =
    layoutHorizontalReverse
        [ okButton okMsg
        , cancelButton cancelMsg
        , deleteButton deleteMsg
        ]


okButton msg =
    Paper.button [ onClick msg ] [ text "Ok" ]


cancelButton msg =
    Paper.button [ onClick msg ] [ text "Cancel" ]


deleteButton msg =
    Paper.button [ onClick msg ] [ text "Delete" ]
