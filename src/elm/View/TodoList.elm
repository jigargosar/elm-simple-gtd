module View.TodoList exposing (..)

import Context
import Dict exposing (Dict)
import Dict.Extra as Dict
import Document
import Dom
import EditMode
import Entity
import GroupEntity.View
import Html.Attributes.Extra exposing (..)
import Html.Events.Extra exposing (onClickStopPropagation)
import Html.Keyed as Keyed
import Keyboard.Extra exposing (Key)
import Ext.Keyboard as Keyboard exposing (KeyboardEvent, onEscape, onKeyDown, onKeyUp)
import Maybe.Extra as Maybe
import Msg exposing (..)
import Polymer.Attributes exposing (icon)
import Project
import Project
import Set exposing (Set)
import Time exposing (Time)
import Toolkit.Helpers exposing (..)
import Toolkit.Operators exposing (..)
import Html exposing (Html, div, hr, node, span, text)
import Html.Attributes exposing (attribute, autofocus, class, classList, disabled, id, style, tabindex, value)
import Html.Events exposing (..)
import Ext.Debug exposing (tapLog)
import Ext.Decode exposing (traceDecoder)
import Json.Decode
import Json.Encode
import List.Extra as List
import Model as Model
import Model exposing (..)
import Todo
import Polymer.Paper as Paper exposing (badge, button, fab, input, item, itemBody, material, tab, tabs)
import Polymer.App exposing (..)
import Ext.Function exposing (..)
import Ext.Function.Infix exposing (..)
import GroupEntity.ViewModel exposing (EntityViewModel)
import Todo.View exposing (EditViewModel)
import Tuple2
import View.Shared exposing (..)
import ViewModel
import WebComponents
import EntityList


filtered : ViewModel.Model -> Model -> Html Msg
filtered viewModel model =
    let
        createTodoView todo =
            Todo.View.initKeyed (viewModel.createTodoViewModel (tabindex -1) todo)
    in
        model
            |> Model.getTodoListForCurrentView
            .|> createTodoView
            |> Keyed.node "paper-listbox"
                [ stringProperty "selected" "0"
                , stringProperty "selectedAttribute" "selected"
                ]
