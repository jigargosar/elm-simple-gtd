module View.EntityList exposing (..)

import Context
import Dict exposing (Dict)
import Dict.Extra as Dict
import Document
import Dom
import EditMode
import Html.Attributes.Extra exposing (..)
import Html.Events.Extra exposing (onClickStopPropagation)
import Html.Keyed as Keyed
import Keyboard.Extra exposing (Key)
import Ext.Keyboard as Keyboard exposing (KeyboardEvent, onEscape, onKeyUp)
import Maybe.Extra as Maybe
import Model.Internal as Model
import Msg exposing (..)
import Polymer.Attributes exposing (icon)
import Project
import Project
import Set exposing (Set)
import Time exposing (Time)
import Toolkit.Helpers exposing (..)
import Toolkit.Operators exposing (..)
import Html exposing (Html, div, hr, node, span, text)
import Html.Attributes exposing (attribute, autofocus, class, classList, disabled, id, style, value)
import Html.Events exposing (..)
import Ext.Debug exposing (tapLog)
import Ext.Decode exposing (traceDecoder)
import Json.Decode
import Json.Encode
import List.Extra as List
import Model as Model
import Model.Types exposing (..)
import Todo
import Polymer.Paper as Paper exposing (badge, button, fab, input, item, itemBody, material, tab, tabs)
import Polymer.App exposing (..)
import Ext.Function exposing (..)
import Entity.ViewModel
import Todo.View exposing (EditTodoViewModel)
import View.Shared exposing (..)
import WebComponents


filtered : Model -> Html Msg
filtered =
    apply2
        ( View.Shared.createSharedViewModel >> Todo.View.createKeyedItem
        , Model.getFilteredTodoList
        )
        >> (\( todoView, todoList ) ->
                Keyed.node "paper-listbox"
                    [ stringProperty "selected" "0"
                    , stringProperty "selectable" "paper-item"
                    , stringProperty "selectedAttribute" "selected"
                    ]
                    (todoList .|> todoView)
           )


groupByEntity : List Entity.ViewModel.EntityItemModel -> Model -> Html Msg
groupByEntity entityVMs model =
    let
        vc =
            View.Shared.createSharedViewModel model

        groupItems vm =
            ( vm.id, entityListItemView vc vm )
                :: (vm.todoList .|> Todo.View.createKeyedItem vc)
    in
        Keyed.node "paper-listbox" [] (entityVMs |> List.concatMap groupItems)


singletonEntity entityVMs id =
    let
        vmSingleton =
            entityVMs |> List.find (.id >> equals id) |> Maybe.toList
    in
        groupByEntity vmSingleton


entityListItemView vc vm =
    if vm.id /= "" then
        vc.getMaybeEditEntityFormForEntityId vm.id
            |> Maybe.unpack (\_ -> defaultView vm) (editEntityView # vm)
    else
        defaultView vm


defaultView vm =
    Paper.item [ class "entity-item" ]
        [ itemBody [] [ View.Shared.defaultBadge vm ]
        , showOnHover [ settingsButton vm.startEditingMsg ]
        ]


editEntityView editModel vm =
    Paper.item [ class "entity-item" ]
        [ itemBody []
            [ input
                [ class "edit-entity-name-input auto-focus"
                , stringProperty "label" "Name"
                , value (editModel.name)
                , onInput vm.onNameChanged
                , onClickStopPropagation (Msg.FocusPaperInput ".edit-entity-name-input")

                --                        , onKeyUp vm.onKeyUp
                ]
                []
            , row
                [ button [ onClick vm.onSaveClicked ] [ "Save" |> text ]
                , button [ onClick vm.onCancelClicked ] [ "Cancel" |> text ]
                , expand []
                , WebComponents.iconButton "delete" [ onClick Msg.SelectionTrashClicked ]
                ]
            ]
        ]
