module View.ProjectList exposing (..)

import Dom
import Html.Attributes.Extra exposing (..)
import Html.Keyed as Keyed
import Keyboard.Extra exposing (Key)
import KeyboardExtra as KeyboardExtra exposing (KeyboardEvent, onEscape, onKeyUp)
import Model.ProjectList
import Model.TodoList exposing (TodoGroupViewModel)
import Msg exposing (..)
import Polymer.Attributes exposing (icon)
import Project
import Time exposing (Time)
import Toolkit.Helpers exposing (..)
import Toolkit.Operators exposing (..)
import Html exposing (Html, div, hr, node, span, text)
import Html.Attributes exposing (attribute, autofocus, class, classList, id, style, value)
import Html.Events exposing (..)
import DebugExtra.Debug exposing (tapLog)
import DecodeExtra exposing (traceDecoder)
import Json.Decode
import Json.Encode
import List.Extra as List
import Model as Model
import Model.Types exposing (..)
import Polymer.Paper as Paper exposing (badge, button, fab, iconButton, item, itemBody, material, menu, tab, tabs)
import Polymer.App exposing (..)
import FunctionExtra exposing (..)
import View.Todo


projectListView m =
    div []
        [ Keyed.node "paper-material"
            [ class "project-list" ]
            (m |> Model.ProjectList.getProjectList >> projectItems)
        ]


projectItems =
    List.map (apply2 ( Project.getId, projectItem ))


projectItem project =
    item [ class "project-item" ] [ itemBody [] [ project |> Project.getName >> text ] ]
