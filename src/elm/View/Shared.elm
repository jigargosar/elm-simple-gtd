module View.Shared exposing (..)

import Context
import Dict exposing (Dict)
import Document exposing (Id)
import EditMode exposing (EditMode, EditTodoModel)
import Html exposing (Html, div, text)
import Html.Attributes exposing (class, style, tabindex)
import Html.Attributes.Extra exposing (intProperty)
import Html.Events exposing (onClick)
import Json.Encode
import Model
import Model.EditMode
import Polymer.Attributes exposing (icon)
import Polymer.Paper exposing (badge, iconButton)
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
    , maybeEditTodoModel : Maybe EditTodoModel
    , editMode : EditMode
    , projectIdToNameDict : Dict Id Project.Name
    , contextByIdDict : Dict Id Context.Model
    , selection : Set Todo.Id
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
    }


defaultBadge : { x | name : String, count : Int } -> Html msg
defaultBadge vm =
    div []
        [ div [] [ text vm.name ]
        , badge [ tabindex -1, intProperty "label" (vm.count) ] []
        ]


row =
    div [ class "row" ]


expand =
    div [ class "flex11" ]


iconButton iconName onClickHandler =
    Polymer.Paper.iconButton [ icon iconName, onClick onClickHandler ] []


trashButton =
    iconButton "delete"


showOnHover =
    div [ class "show-on-hover" ]


hideOnHover bool children =
    div [ class "hide-on-hover" ]
        (if bool then
            children
         else
            []
        )
