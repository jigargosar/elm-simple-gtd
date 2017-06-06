module Main.Menu exposing (..)

import Main exposing (Model)
import Toolkit.Helpers exposing (..)
import Toolkit.Operators exposing (..)
import Ext.Function exposing (..)
import Ext.Function.Infix exposing (..)
import List.Extra as List
import Maybe.Extra as Maybe
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Html.Events.Extra exposing (onClickStopPropagation)
import Model exposing (Msg)
import Polymer.Paper as Paper
import Project


projectMenu : Model -> List (Html Msg)
projectMenu model =
    let
        createListItem onItemClick project =
            Paper.item
                [ onClick (onItemClick project) ]
                [ project |> Project.getName >> text ]

        view todo =
            let
                onItemClick =
                    Model.SetTodoProject # todo
            in
                Paper.material [ id "project-menu", attribute "data-prevent-default-keys" "Tab" ]
                    [ Paper.listbox []
                        (Model.getActiveProjects model .|> createListItem onItemClick)
                    ]
    in
        model |> Model.getMaybeEditTodoProjectForm ?|> view |> Maybe.toList
