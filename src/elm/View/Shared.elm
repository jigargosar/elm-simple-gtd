module View.Shared exposing (..)

import Context
import Dict exposing (Dict)
import Document exposing (Id)
import EditMode exposing (EditMode, TodoForm)
import Html exposing (Html, div, span, text)
import Html.Attributes exposing (class, style, tabindex)
import Html.Attributes.Extra exposing (intProperty)
import Html.Events exposing (onClick)
import Html.Events.Extra exposing (onClickStopPropagation)
import Json.Encode
import Model
import Model.EditMode
import Polymer.Attributes exposing (icon)
import Polymer.Paper exposing (badge)
import Set exposing (Set)
import Time exposing (Time)
import Toolkit.Helpers exposing (..)
import Toolkit.Operators exposing (..)
import Ext.Function exposing (..)
import Ext.Function.Infix exposing (..)
import List.Extra as List
import Maybe.Extra as Maybe
import Model.Types exposing (Model)
import Project
import Model.Internal as Model
import Project
import Todo


type alias SharedViewModel =
    { now : Time
    , encodedProjectNames : Json.Encode.Value
    , encodedContextNames : Json.Encode.Value
    , maybeEditTodoModel : Maybe TodoForm
    , editMode : EditMode
    , projectIdToNameDict : Dict Id Project.Name
    , contextByIdDict : Dict Id Context.Model
    , selection : Set Todo.Id
    , showDetails : Bool
    }


createSharedViewModel : Model -> SharedViewModel
createSharedViewModel model =
    { now = Model.getNow model
    , encodedProjectNames = Model.getProjectStore model |> Project.getEncodedProjectNames
    , encodedContextNames = Model.getEncodedContextNames model
    , maybeEditTodoModel = Model.EditMode.getMaybeEditTodoModel model
    , projectIdToNameDict = Model.getProjectStore model |> Project.getProjectIdToNameDict
    , contextByIdDict = Model.getContextByIdDict model
    , selection = Model.getSelectedTodoIdSet model
    , editMode = Model.getEditMode model
    , showDetails = Model.isShowDetailsKeyPressed model
    }


defaultBadge : { x | name : String, count : Int } -> Html msg
defaultBadge vm =
    --    div [ class "ellipsis" ]
    --        [ div [] [ text vm.name ]
    --        , badge [ tabindex -1, intProperty "label" (vm.count) ] []
    --        ]
    row
        [ div [ class "ellipsis" ] [ vm.name |> text ]
        , div [ style [ "margin-left" => "0.5rem" ] ] [ " (" ++ (vm.count |> toString) ++ ")" |> text ]
        ]


row =
    div [ class "row" ]


rowItemStretched =
    div [ class "row-item-stretched" ]


colItemStretched =
    div [ class "col-item-stretched" ]


col =
    div [ class "col" ]


expand =
    div [ class "flex11" ]


sharedIconButton iconName onClickHandler =
    Polymer.Paper.iconButton [ icon iconName, onClickStopPropagation onClickHandler ] []


startIconButton =
    sharedIconButton "av:play-circle-outline"


trashIcon =
    Html.node "iron-icon" [ icon "delete" ] []


trashButton =
    sharedIconButton "delete"


settingsButton =
    sharedIconButton "settings"


showOnHover =
    div [ class "show-on-hover" ]


hideOnHover bool children =
    div [ class "hide-on-hover" ]
        (if bool then
            children
         else
            []
        )
