module Menu exposing (..)

import Document
import Ext.Keyboard exposing (onKeyDownStopPropagation)
import Html.Attributes.Extra exposing (intProperty)
import Model exposing (Model, commonMsg)
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
import Todo


type alias ViewModel item msg =
    { items : List item
    , onSelect : item -> msg
    , itemDomId : item -> String
    , domId : String
    , itemView : item -> Html msg
    , isSelected : item -> Bool
    }


view vm =
    let
        selectedIndex =
            vm.items |> List.findIndex vm.isSelected ?= 0

        createListItem item =
            div
                [ onClick (vm.onSelect item) ]
                [ vm.itemView item ]
    in
        div
            [ class "modal-background"
            , onKeyDownStopPropagation ((\_ -> commonMsg.noOp))
            , onClickStopPropagation Model.DeactivateEditingMode
            ]
            [ div [ id vm.domId, attribute "data-prevent-default-keys" "Tab" ]
                (vm.items .|> createListItem)
            ]
