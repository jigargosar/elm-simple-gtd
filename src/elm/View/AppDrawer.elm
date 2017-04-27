module View.AppDrawer exposing (..)

import Entity.ViewModel
import Html.Attributes.Extra exposing (..)
import Html.Events.Extra exposing (onClickPreventDefaultAndStopPropagation, onClickStopPropagation)
import Html.Keyed as Keyed
import Html exposing (Attribute, Html, div, hr, node, span, text)
import Html.Attributes exposing (attribute, autofocus, checked, class, classList, id, style, tabindex, value)
import Html.Events exposing (..)
import Ext.Keyboard as Keyboard exposing (onEscape, onKeyUp)
import Model.TodoStore
import Msg exposing (Msg(SetView))
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
import Model.Types exposing (..)
import View.Shared exposing (..)
import WebComponents exposing (iconP, onBoolPropertyChanged)


view contextVM projectVM m =
    App.drawer []
        [ App.headerLayout
            [ --            style [ "height" => "100%", "overflow" => "scroll" ]
              attribute "has-scrolling-region" ""
            ]
            [ App.header []
                [--            App.toolbar [] [ Html.h2 [] [ text "" ] ]
                ]
            , menu
                [ stringProperty "selected" "0"
                , stringProperty "selectable" "paper-item"
                , stringProperty "selectedAttribute" "selected"
                ]
                (entityList contextVM
                    ++ [ divider ]
                    ++ entityList projectVM
                    ++ [ divider ]
                    ++ [ binItemView m
                       , doneItemView m
                       , syncView m
                       ]
                )
            ]
        ]


divider =
    div [ class "divider" ] []


entityList { vmList, viewType, title, showDeleted, onAddClicked } =
    [ item [ class "has-hover-elements", onClick (SetView viewType) ]
        [ itemBody [] [ div [ class "font-headline" ] [ text title ] ]
        , div [ class "show-on-hover layout horizontal center" ]
            [ iconButton [ iconP "add", onClick onAddClicked ] []
            , toggleButton [ checked showDeleted, onClick Msg.ToggleShowDeletedEntity ] []
            , trashIcon
            ]
        ]
--    , divider
    ]
        ++ (List.map entityItem vmList)


binItemView m =
    item [ onClick (SetView BinView) ] [ Html.h4 [] [ text "Bin" ] ]


doneItemView m =
    item [ onClick (SetView DoneView) ] [ Html.h4 [] [ text "Done" ] ]


syncView m =
    item [ onClick (SetView SyncView) ] [ Html.h4 [] [ text "Sync Settings" ] ]



--onPropertyChanged decoder propertyName tagger =


entityItem : Entity.ViewModel.ViewModel -> Html Msg
entityItem vm =
    item [ class "", onBoolPropertyChanged "focused" vm.onActiveStateChanged ]
        ([ itemBody [] [ View.Shared.defaultBadge vm ]
         , hoverIcons vm
         , hideOnHover vm.isDeleted [ trashButton Msg.NoOp ]
         ]
        )


hoverIcons vm =
    div [ class "show-on-hover" ]
        [ settingsButton vm.startEditingMsg ]
