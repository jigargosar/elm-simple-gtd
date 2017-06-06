module Menu exposing (..)

import Document
import Model exposing (Model)
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
    }


view vm =
    let
        createListItem item =
            Paper.item
                [ onClick (vm.onSelect item) ]
                [ vm.itemView item ]
    in
        Paper.material [ id vm.domId, attribute "data-prevent-default-keys" "Tab" ]
            [ Paper.listbox []
                (vm.items .|> createListItem)
            ]
