module View.ProjectList exposing (..)

import Dom
import Html.Attributes.Extra exposing (..)
import Html.Keyed as Keyed
import Keyboard.Extra exposing (Key)
import KeyboardExtra as KeyboardExtra exposing (KeyboardEvent, onEscape, onKeyUp)
import Model.EditMode
import Model.TodoList exposing (TodoGroupViewModel)
import Msg exposing (..)
import Polymer.Attributes exposing (icon)
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
import Types exposing (EditMode(..), Model, ModelF)
import Todo as Todo exposing (TodoGroup(Inbox), Todo, TodoId)
import Polymer.Paper as Paper exposing (badge, button, fab, iconButton, item, itemBody, material, menu, tab, tabs)
import Polymer.App exposing (..)
import FunctionExtra exposing (..)
import View.Todo


projectListView m =
    Keyed.node "paper-material" [ class "project-list" ] (projectItems)


projectItems =
    [ ( "1", projectItem "Kill Todoist" )
    , ( "2", projectItem "Kill OneTab" )
    ]


projectItem name =
    item [ class "project-item" ] [ itemBody [] [ text name ] ]
