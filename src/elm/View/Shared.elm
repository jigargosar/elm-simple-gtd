module View.Shared exposing (..)

import Context
import Dict exposing (Dict)
import Document exposing (Id)
import ExclusiveMode exposing (ExclusiveMode)
import Entity exposing (Entity)
import OldGroupEntity.ViewModel
import Html exposing (Html, div, span, text)
import Html.Attributes exposing (class, style, tabindex)
import Html.Attributes.Extra exposing (boolProperty, intProperty)
import Html.Events exposing (onClick)
import Html.Events.Extra exposing (onClickStopPropagation)
import Json.Encode
import Model
import Model
import Polymer.Attributes exposing (icon)
import Polymer.Paper as Paper exposing (badge)
import Set exposing (Set)
import Time exposing (Time)
import Toolkit.Helpers exposing (..)
import Toolkit.Operators exposing (..)
import Ext.Function exposing (..)
import Ext.Function.Infix exposing (..)
import List.Extra as List
import Maybe.Extra as Maybe
import Model exposing (Model)
import Project
import Project
import Todo
import Todo.Form
import Todo.ReminderForm


defaultBadge : { x | name : String, count : Int } -> Html msg
defaultBadge vm =
    div [ class "layout horizontal center" ]
        [ div [ class "font-nowrap" ] [ vm.name |> text ]
        , div [ style [ "padding" => "0 0 1rem 0.1rem " ], class "text-secondary" ]
            [ " " ++ (vm.count |> toString) ++ "" |> text ]
        ]


badge : String -> Int -> Html msg
badge name count =
    div [ class "layout horizontal center" ]
        [ div [ class "font-nowrap" ] [ name |> text ]
        , div [ style [ "padding" => "0 0 1rem 0.1rem " ], class "text-secondary" ]
            [ " " ++ (count |> toString) ++ "" |> text ]
        ]


defaultOkCancelButtons =
    defaultOkCancelButtonsWith []


defaultOkCancelButtonsWith list =
    okCancelButtonsWith Model.OnSaveCurrentForm Model.OnDeactivateEditingMode list


defaultOkCancelDeleteButtons deleteMsg =
    defaultOkCancelButtonsWith [ deleteButton deleteMsg ]


okCancelButtonsWith okMsg cancelMsg list =
    div [ class "layout horizontal-reverse" ]
        ([ okButton okMsg
         , cancelButton cancelMsg
         ]
            ++ list
        )


okButton msg =
    Paper.button [ onClick msg ] [ text "Ok" ]


cancelButton msg =
    Paper.button [ onClick msg ] [ text "Cancel" ]


deleteButton msg =
    Paper.button [ onClick msg ] [ text "Delete" ]
