module View.AppDrawer exposing (..)

import Document
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
import WebComponents exposing (iconP, onBoolPropertyChanged, paperIconButton)


view contextVM projectVM m =
    App.drawer
        [ boolProperty "swipeOpen" True
        ]
        [ App.headerLayout
            [ attribute "has-scrolling-region" ""
            ]
            [ App.header
                [ boolProperty "fixed" True
                ]
                [ App.toolbar []
                    [ paperIconButton [ iconP "menu", attribute "drawer-toggle" "", onClick Msg.ToggleDrawer ] []
                    , headLineText "View Name"
                    ]
                ]
            , menu
                [ stringProperty "selectable" "paper-item"
                , stringProperty "selectedAttribute" "selected"
                , stringProperty "attrForSelected" "selected"
                ]
                (entityList contextVM m.mainViewType
                    ++ [ divider ]
                    ++ entityList projectVM m.mainViewType
                    ++ [ divider ]
                    ++ [ switchViewItem BinView "Bin"
                       , switchViewItem DoneView "Done"
                       , switchViewItem SyncView "Sync Settings"
                       ]
                )
            ]
        ]


divider =
    div [ class "divider" ] []


entityList { vmList, viewType, title, showDeleted, onAddClicked } mainViewType =
    let
        maybeSelectedId =
            case mainViewType of
                ProjectView id ->
                    Just id

                ContextView id ->
                    Just id

                _ ->
                    Nothing

        isSelected =
            maybeSelectedId |> Maybe.unwrap (\id -> False) equals
    in
        [ item [ class "has-hover-elements", onClick (SetView viewType) ]
            [ itemBody [] [ headLineText title ]
            , div [ class "show-on-hover layout horizontal center" ]
                [ toggleButton [ checked showDeleted, onClick Msg.ToggleShowDeletedEntity ] []
                , trashIcon
                , iconButton [ iconP "add", onClick onAddClicked ] []
                ]
            ]

        --    , divider
        ]
            ++ (List.map (entityItem isSelected) vmList)


headLineText title =
    div [ class "font-title" ] [ text title ]


switchViewItem viewType title =
    item [ onClick (SetView viewType) ] [ headLineText title ]



--onPropertyChanged decoder propertyName tagger =


entityItem : (Document.Id -> Bool) -> Entity.ViewModel.ViewModel -> Html Msg
entityItem isSelected vm =
    --    let
    --        _ =
    --            Debug.log "isSelected vm.id" (isSelected vm.id)
    --    in
    item [ class "", boolProperty "selected" (isSelected vm.id), onBoolPropertyChanged "focused" vm.onActiveStateChanged ]
        ([ itemBody [] [ View.Shared.defaultBadge vm ]
         , hoverIcons vm
         , hideOnHover vm.isDeleted [ trashButton Msg.NoOp ]
         ]
        )


hoverIcons vm =
    div [ class "show-on-hover" ]
        [ settingsButton vm.startEditingMsg ]
