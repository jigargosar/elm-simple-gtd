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
        [ div [ class "ellipsis" ] [ vm.name |> text ]
        , div [ style [ "padding" => "0 0 1rem 0.1rem " ], class "text-secondary" ]
            [ " " ++ (vm.count |> toString) ++ "" |> text ]
        ]


badge : String -> Int -> Html msg
badge name count =
    div [ class "layout horizontal center" ]
        [ div [ class "font-nowrap ellipsis" ] [ name |> text ]
        , div [ style [ "padding" => "0 0 1rem 0.1rem " ], class "text-secondary" ]
            [ " " ++ (count |> toString) ++ "" |> text ]
        ]


sharedIconButton iconName onClickHandler =
    Paper.iconButton [ icon iconName, onClickStopPropagation onClickHandler ] []


doneButton =
    sharedIconButton "done"


dismissButton =
    sharedIconButton "cancel"


snoozeButton =
    sharedIconButton "av:snooze"


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


defaultOkCancelButtons =
    okCancelButtons Model.OnSaveCurrentForm Model.OnDeactivateEditingMode


defaultOkCancelDeleteButtons deleteMsg =
    okCancelDeleteButtons Model.OnSaveCurrentForm Model.OnDeactivateEditingMode deleteMsg


layoutHorizontalReverse =
    div [ class "layout horizontal-reverse" ]


okCancelButtons okMsg cancelMsg =
    layoutHorizontalReverse
        [ okButton okMsg
        , cancelButton cancelMsg
        ]


okCancelDeleteButtons okMsg cancelMsg deleteMsg =
    layoutHorizontalReverse
        [ okButton okMsg
        , cancelButton cancelMsg
        , deleteButton deleteMsg
        ]


okButton msg =
    Paper.button [ onClick msg ] [ text "Ok" ]


cancelButton msg =
    Paper.button [ onClick msg ] [ text "Cancel" ]


deleteButton msg =
    Paper.button [ onClick msg ] [ text "Delete" ]
