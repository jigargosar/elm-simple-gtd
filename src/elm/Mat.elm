module Mat exposing (..)

import AppColors
import Color
import Color.Mixing
import Html exposing (..)
import Html.Attributes exposing (..)
import Material
import Material.Button
import Material.Icon
import Material.Options
import Model
import X.Function exposing (..)
import X.Function.Infix exposing (..)
import Toolkit.Operators exposing (..)
import X.Html exposing (onClickStopPropagation)
import X.Keyboard
import X.String
import Json.Decode as D exposing (Decoder)
import Json.Decode.Pipeline as D
import Json.Encode as E


stopPropagation =
    { stopPropagation = True
    , preventDefault = False
    }


preventDefault =
    { stopPropagation = False
    , preventDefault = True
    }


stopAll =
    { stopPropagation = True
    , preventDefault = True
    }


onStopPropagation eventName =
    Material.Options.onWithOptions eventName stopPropagation


onStopPropagation2 eventName =
    D.succeed >> onStopPropagation eventName


iconD name =
    i [ class "default-color material-icons" ] [ text name ]


icon name =
    i [ class "material-icons" ] [ text name ]


iconA__ name attrs =
    let
        allAttr =
            class "material-icons" :: attrs
    in
        i allAttr [ text name ]


iconM icon =
    iconA__ icon.name [ style [ "color" => AppColors.encode icon.color ] ]


type alias BtnConfig =
    { id : String
    , class : String
    , classList : List ( String, Bool )
    , iconName : String
    , onClick : Model.Msg
    , tabIndex : Int
    , trackingId : String
    , primaryFAB : Bool
    , mdl : Material.Model
    , iconProps : List (Material.Icon.Property Model.Msg)
    }


defaultBtnConfig =
    { id = ""
    , class = ""
    , classList = []
    , iconName = ""
    , msg = Model.noop
    , tabIndex = -2
    , trackingId = ""
    , primaryFAB = False
    , mdl = Material.model
    , iconProps = []
    }


primaryFAB iconName msg configFn =
    ib iconName msg <| configFn >> (\c -> { c | primaryFAB = True })


iconBtn2 name clickHandler =
    ib name clickHandler identity


iconBtn3 name tabIndexV clickHandler =
    ib name clickHandler (\c -> { c | tabIndex = tabIndexV })


iconBtn4 name tabIndexV className clickHandler =
    ib name clickHandler (\c -> { c | tabIndex = tabIndexV, class = className })


smallIconBtn name clickHandler configFn =
    configFn
        >> (\c ->
                { c
                    | iconProps = c.iconProps ++ [ Material.Icon.size18 ]
                }
           )
        |> ib name clickHandler


ib iconName msg configFn =
    defaultBtnConfig |> configFn >> (\c -> { c | iconName = iconName, msg = msg }) >> ibc


ibc config =
    let
        trackingId =
            config.trackingId
                |> when X.String.isBlank (\_ -> "ma2-" ++ config.iconName)

        cs =
            [ ( config.class, config.class |> X.String.isBlank >> not )
            ]
                ++ config.classList
                |> classListAsClass

        btnAttr =
            [ nothingWhen (equals -2) tabindex config.tabIndex
            , nothingWhen X.String.isBlank id config.id
            ]
                |> List.filterMap identity
                .|> Material.Options.attribute
                |++ [ onStopPropagation2 "click" config.msg
                    , Material.Options.attribute <| attribute "data-btn-name" trackingId
                    ]
                |> Material.Options.many
    in
        Material.Button.render Model.Mdl
            [ 0 ]
            config.mdl
            [ Material.Options.many
                (if config.primaryFAB then
                    [ Material.Button.fab, Material.Button.colored, Material.Options.cs "mdl-button--page-fab" ]
                 else
                    [ Material.Button.icon ]
                )
            , Material.Options.cs cs
            , btnAttr
            ]
            [ Material.Icon.view config.iconName config.iconProps ]


classListAsClass list =
    list
        |> List.filter Tuple.second
        |> List.map Tuple.first
        |> String.join " "


bigIconTextBtn iconName textV clickHandler =
    Html.button
        [ class "big-icon-text-btn"
        , onClickStopPropagation clickHandler
        ]
        [ i [ class "material-icons" ] [ text iconName ]
        , div [] [ text textV ]
        ]


btn textV attributes =
    div attributes [ Html.button [ class "btn" ] [ text textV ] ]


btnFlat textV attributes =
    div attributes
        [ Html.a [ class "btn btn-flat" ] [ text textV ] ]


divider =
    div [ class "divider" ] []
