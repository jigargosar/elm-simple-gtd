module View.ProjectList exposing (..)

import Dom
import Html.Attributes.Extra exposing (..)
import Html.Events.Extra exposing (onClickStopPropagation)
import Html.Keyed as Keyed
import Keyboard.Extra exposing (Key)
import Ext.Keyboard as Keyboard exposing (KeyboardEvent, onEscape, onKeyUp)
import Model.Internal as Model
import ProjectStore
import Model.TodoList exposing (TodoContextViewModel)
import Msg exposing (..)
import Polymer.Attributes exposing (icon)
import Project
import Time exposing (Time)
import Toolkit.Helpers exposing (..)
import Toolkit.Operators exposing (..)
import Html exposing (Html, div, hr, node, span, text)
import Html.Attributes exposing (attribute, autofocus, class, classList, id, style, value)
import Html.Events exposing (..)
import Ext.Debug exposing (tapLog)
import Ext.Decode exposing (traceDecoder)
import Json.Decode
import Json.Encode
import List.Extra as List
import Model as Model
import Model.Types exposing (..)
import Polymer.Paper as Paper exposing (badge, button, fab, iconButton, item, itemBody, material, menu, tab, tabs)
import Polymer.App exposing (..)
import Ext.Function exposing (..)
import View.Todo


projectListView m =
    div []
        [ Keyed.node "paper-material"
            [ class "project-list" ]
            (m |> Model.getProjectStore >> ProjectStore.asList >> List.map projectItem)
        ]


projectItem project =
    let
        vm =
            createProjectItemViewModel project
    in
        ( vm.key
        , item
            [ class "project-item"
            , onClickStopPropagation vm.onClick
            ]
            [ itemBody [] [ text vm.name ] ]
        )


createProjectItemViewModel project =
    let
        projectId =
            Project.getId project
    in
        { onClick = projectId |> ProjectView >> Msg.SetMainViewType
        , name = project |> Project.getName
        , key = projectId
        }
