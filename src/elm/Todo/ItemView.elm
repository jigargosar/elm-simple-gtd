module Todo.ItemView exposing (ScheduleViewModel, TodoViewModel, keyedItem)

import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import List.Extra as List
import Mat
import Material
import Regex
import RegexHelper
import String.Extra as String
import Toolkit.Operators exposing (..)
import X.Function.Infix exposing (..)
import X.Html exposing (onChange, onClickStopPropagation, onMouseDownStopPropagation)
import X.Keyboard exposing (KeyboardEvent, onKeyDown)


type alias TodoViewModel msg =
    { key : String
    , displayText : String
    , isDone : Bool
    , isDeleted : Bool
    , onKeyDownMsg : KeyboardEvent -> msg
    , projectDisplayName : String
    , contextDisplayName : String
    , startEditingMsg : msg
    , toggleDoneMsg : msg
    , canBeFocused : Bool
    , showContextDropDownMsg : msg
    , showProjectDropDownMsg : msg
    , reminder : ScheduleViewModel msg
    , onFocusIn : msg
    , tabindexAV : Int
    , isSelected : Bool
    , mdl : Material.Model
    , noop : msg
    , onMdl : Material.Msg msg -> msg
    }


type alias ScheduleViewModel msg =
    { displayText : String
    , isOverDue : Bool
    , startEditingMsg : msg
    }


type alias TodoKeyedItemView msg =
    ( String, Html msg )


keyedItem : TodoViewModel msg -> TodoKeyedItemView msg
keyedItem vm =
    ( vm.key, item vm )


item : TodoViewModel msg -> Html msg
item vm =
    div
        [ classList
            [ "todo-item focusable-list-item collection-item" => True
            , "selected" => vm.isSelected
            , "can-be-focused" => vm.canBeFocused
            ]
        , X.Html.onFocusIn vm.onFocusIn

        --        , onClick vm.onFocusIn
        , tabindex vm.tabindexAV
        , onKeyDown vm.onKeyDownMsg
        , attribute "data-key" vm.key
        ]
        [ div
            [ class "display-text-container layout horizontal"
            ]
            [ div [ class "self-start" ] [ doneIconButton vm ]
            , div [ class "display-text", onClick vm.startEditingMsg ] (parseDisplayText vm)
            ]
        , div
            [ class "layout horizontal end-justified"
            ]
            [ div [ style [ "margin" => "0 8px" ] ] [ editScheduleButton vm ]
            , div [ style [ "padding" => "0 8px" ], class "layout horizontal center-center" ]
                [ a
                    [ id ("edit-context-button-" ++ vm.key)
                    , style [ "color" => "black", "min-width" => "3rem" ]
                    , onClick vm.showContextDropDownMsg
                    , tabindex vm.tabindexAV
                    ]
                    [ text vm.contextDisplayName ]
                ]
            , div [ style [ "padding" => "0 8px" ], class "layout horizontal center-center" ]
                [ a
                    [ id ("edit-project-button-" ++ vm.key)
                    , style [ "color" => "black", "min-width" => "3rem" ]
                    , onClick vm.showProjectDropDownMsg
                    , tabindex vm.tabindexAV
                    ]
                    [ text vm.projectDisplayName ]
                ]
            ]
        ]


parseDisplayText vm =
    --Markdown.toHtml Nothing displayText
    let
        createLink url =
            a
                [ href url
                , target "_blank"
                , onMouseDownStopPropagation vm.noop
                , tabindex vm.tabindexAV
                ]
                [ url |> RegexHelper.stripUrlPrefix |> String.ellipsis 30 |> String.toLower |> text ]

        linkStrings =
            Regex.find Regex.All RegexHelper.url vm.displayText
                .|> .match
                >> createLink

        nonLinkStrings =
            Regex.split Regex.All RegexHelper.url vm.displayText
                .|> text
    in
    List.interweave nonLinkStrings linkStrings


classListAsClass list =
    list
        |> List.filter Tuple.second
        |> List.map Tuple.first
        |> String.join " "


doneIconButton : TodoViewModel msg -> Html msg
doneIconButton vm =
    Mat.iconBtn4 vm.onMdl
        "done"
        vm.tabindexAV
        (classListAsClass [ "done-icon" => True, "is-done" => vm.isDone ])
        vm.toggleDoneMsg


editScheduleButton vm =
    div
        [ id ("edit-schedule-button-" ++ vm.key)
        , class "layout horizontal center-center"
        , onClick vm.reminder.startEditingMsg
        ]
        [ div
            [ classList
                [ "overdue" => vm.reminder.isOverDue
                , "reminder-text" => True
                ]
            ]
            [ vm.reminder.displayText |> text ]
        , Mat.iconBtn vm.onMdl
            vm.mdl
            [ Mat.tabIndex vm.tabindexAV
            ]
            [ Mat.iconSmall "schedule" ]
        ]
