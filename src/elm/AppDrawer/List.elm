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
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Html.Events.Extra exposing (onClickStopPropagation)
import Ext.Keyboard as Keyboard exposing (onEscape, onKeyUp)
import Model exposing (Msg(SwitchView), commonMsg)
import String.Extra
import Maybe.Extra as Maybe
import Toolkit.Helpers exposing (..)
import Toolkit.Operators exposing (..)
import Ext.Debug exposing (tapLog)
import Ext.Decode exposing (traceDecoder)
import Json.Decode
import Json.Encode
import List.Extra as List
import Model exposing (..)
import Todo
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
        div [ class "app-drawer-list-container" ]
            [ ul []
                ([]
                    ++ entityListView contexts model.mainViewType
                    ++ entityListView projects model.mainViewType
                    ++ [ onSetEntityListViewItem "delete" Entity.BinView "Bin"
                       , onSetEntityListViewItem "done" Entity.DoneView "Done"
                       , switchViewItem "sync" SyncView "Custom Sync"
                       ]
                    ++ [ Material.divider ]
                    ++ [ toggleDeletedItem model ]
                )
            ]


toggleDeletedItem model =
    li [ onClick Model.ToggleShowDeletedEntity ]
        [ div [ class "switch" ]
            [ label []
                [ input
                    [ type_ "checkbox"
                    , checked model.showDeleted
                    , tabindex -1
                    ]
                    []
                , span [ class "lever" ] []
                ]
            ]
        , div [] [ text "Show/Hide Deleted Contexts/Projects" ]
        ]


entityListView { className, entityList, viewType, title, showDeleted, onAddClicked, icon, onToggleExpanded, isExpanded } mainViewType =
    [ li []
        [ Material.iconA icon.name
            [ style [ "color" => icon.color ] ]
        , Html.h5 [ onClick (SwitchView (EntityListView viewType)) ] [ text title ]
        , Material.iconButton "expand_more" [ onClick onToggleExpanded ]
        ]
    , li [ classList [ "list-container" => True, "expanded" => isExpanded ] ]
        [ ul []
            ([ li
                [ class ""
                , onClickPreventDefaultAndStopPropagation onAddClicked
                ]
                [ Material.icon "add"
                , div [] [ text "Add New" ]
                ]
             ]
                ++ List.map entityListItem entityList
                ++ [ Material.divider ]
            )
        ]
    ]


entityListItem : OldGroupEntity.ViewModel.DocumentWithNameViewModel -> Html Msg
entityListItem vm =
    li
        [ class ""
        , onClick (vm.onActiveStateChanged True)
        ]
        [ Material.iconA vm.icon.name [ style [ "color" => vm.icon.color ] ]
        , View.Shared.defaultBadge vm
        ]


switchViewItem iconName viewType title =
    li
        [ class ""
        , onClick (SwitchView viewType)
        ]
        [ Material.icon iconName
        , h5 [] [ text title ]
        ]


onSetEntityListViewItem iconName viewType title =
    li
        [ class ""
        , onClick (OnSetEntityListView viewType)
        ]
        [ Material.icon iconName
        , h5 [] [ text title ]
        ]
