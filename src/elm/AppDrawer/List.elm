module AppDrawer.List exposing (..)

import Material
import Toolkit.Helpers exposing (..)
import Toolkit.Operators exposing (..)
import Ext.Function exposing (..)
import Ext.Function.Infix exposing (..)
import List.Extra as List
import Maybe.Extra as Maybe
import Document
import Entity
import OldGroupEntity.ViewModel
import Html.Attributes.Extra exposing (..)
import Html.Events.Extra exposing (onClickPreventDefaultAndStopPropagation, onClickStopPropagation)
import Html.Keyed as Keyed
import Html exposing (Attribute, Html, a, div, hr, li, node, span, text, ul)
import Html.Attributes exposing (attribute, autofocus, checked, class, classList, href, id, style, tabindex, target, value)
import Html.Events exposing (..)
import Ext.Keyboard as Keyboard exposing (onEscape, onKeyUp)
import Model exposing (Msg(SwitchView), commonMsg)
import String.Extra
import Maybe.Extra as Maybe
import Polymer.Attributes exposing (icon)
import Toolkit.Helpers exposing (..)
import Toolkit.Operators exposing (..)
import Ext.Debug exposing (tapLog)
import Ext.Decode exposing (traceDecoder)
import Json.Decode
import Json.Encode
import List.Extra as List
import Model exposing (..)
import Todo
import Polymer.Paper exposing (..)
import Polymer.App as App
import Ext.Function exposing (..)
import Ext.Function.Infix exposing (..)
import Model exposing (..)
import View.Shared exposing (..)
import ViewModel
import WebComponents exposing (iconA, onBoolPropertyChanged, paperIconButton)


view appVM model =
    let
        { contexts, projects } =
            appVM
    in
        ul [ class "" ]
            [ toggleDeletedItem model
            , entityListView contexts model.mainViewType
            , entityListView projects model.mainViewType
            , onSetEntityListViewItem "delete" Entity.BinView "Bin"
            , onSetEntityListViewItem "done" Entity.DoneView "Done"
            , switchViewItem "notification:sync" SyncView "Custom Sync"
            ]


toggleDeletedItem model =
    toggleButton
        [ class ""
        , checked model.showDeleted
        , onClick Model.ToggleShowDeletedEntity
        ]
        [ text "Toggle Deleted" ]


entityListView { entityList, viewType, title, showDeleted, onAddClicked, icon } mainViewType =
    li [ class "" ]
        [ div [ class "" ]
            [ Material.iconA icon.name [ style [ "color" => icon.color ] ]
            , Html.h5 [ onClick (SwitchView (EntityListView viewType)) ] [ text title ]
            ]
        , div
            [ class ""
            , onClickPreventDefaultAndStopPropagation onAddClicked
            ]
            [ Material.icon "add"
            , div [] [ text "Add New" ]
            ]
        , div [] (List.map entityListItem entityList)
        , Material.divider
        ]


entityListItem : OldGroupEntity.ViewModel.DocumentWithNameViewModel -> Html Msg
entityListItem vm =
    div
        [ class "collection-item layout horizontal center"
        , onClick (vm.onActiveStateChanged True)
        ]
        [ Html.node "iron-icon" [ iconA vm.icon.name, style [ "color" => vm.icon.color ] ] []
        , itemBody [] [ View.Shared.defaultBadge vm ]
        ]


switchViewItem iconName viewType title =
    item [ onClick (SwitchView viewType) ]
        [ Html.node "iron-icon" [ iconA iconName ] []
        , itemBody [] [ text title ]
        ]


onSetEntityListViewItem iconName viewType title =
    item [ onClick (OnSetEntityListView viewType) ]
        [ Html.node "iron-icon" [ iconA iconName ] []
        , itemBody [] [ text title ]
        ]
